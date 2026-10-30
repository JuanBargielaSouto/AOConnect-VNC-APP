require('dotenv').config();
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const readline = require('readline');

const app = express();
app.use(express.json());
app.use(cors());

// Codigo para HASH
const SECRET = process.env.JWT_SECRET;
if (!SECRET) {
  console.error("JWT_SECRET no definida en .env");
  process.exit(1);
}

// ================= DB =================
const db = new sqlite3.Database('./database.db');
db.run("PRAGMA foreign_keys = ON");
// Crear tablas
db.serialize(() => {
	db.run(`
	  CREATE TABLE IF NOT EXISTS users (
	    id INTEGER PRIMARY KEY AUTOINCREMENT,
	    username TEXT UNIQUE,
	    password TEXT,
	    role TEXT NOT NULL DEFAULT 'user'
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS devices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      ip TEXT,
      port TEXT
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS user_devices (
      user_id INTEGER,
      device_id INTEGER,
      PRIMARY KEY (user_id, device_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
    )
  `);
});

// ================= BOSS INIT =================
function ensureBossUser() {

  return new Promise((resolve, reject) => {

    db.get(
      `SELECT COUNT(*) as count FROM users WHERE role = 'boss'`,
      async (err, row) => {

        if (err) {
          console.error("Error comprobando boss:", err);
          reject(err);
          return;
        }

        // Más de un boss -> error
        if (row.count > 1) {
          reject(new Error("Existe más de un usuario boss"));
          return;
        }

        // Ya existe boss
        if (row.count === 1) {
          console.log("Usuario boss encontrado");
          resolve();
          return;
        }

        // ================= CREAR BOSS =================

        console.log("No existe usuario boss.");
        console.log("Crear usuario boss inicial:");

        const rl = readline.createInterface({
          input: process.stdin,
          output: process.stdout
        });

        const question = (text) => {
          return new Promise(resolveQuestion => {
            rl.question(text, resolveQuestion);
          });
        };

        try {

		let username;
		let password;

		// USERNAME
		while (true) {

		  username = await question("Username boss: ");

		  if (username && username.trim().length >= 4) {
			    break;
		  }

		  console.log("El username debe tener al menos 4 caracteres");
		}

		// PASSWORD
		while (true) {

		  password = await question("Password boss: ");

		  if (password && password.length >= 6) {
		    break;
		  }

		  console.log("La contraseña debe tener al menos 6 caracteres");
		}
	          const hash = await bcrypt.hash(password, 10);

          db.run(
            `INSERT INTO users (username, password, role)
             VALUES (?, ?, 'boss')`,
            [username, hash],
            function(err) {

              rl.close();

              if (err) {
                reject(err);
                return;
              }

              console.log("Usuario boss creado correctamente");

              resolve();
            }
          );

        } catch (e) {
          rl.close();
          reject(e);
        }
      }
    );
  });
}

// ================= AUTH =================
//
//LOGIN
app.post('/login', (req,res) =>	{
	const { username, password } = req.body;

	db.get(
		'SELECT * FROM users WHERE username = ?',[username],
	async (err, user) => {
		if (!user) return res.status(401).send("Usuario no existe");

		const valid = await bcrypt.compare(password, user.password);

		if (!valid) return res.status(401).send("Password incorrecta");

		const token = jwt.sign({ userId: user.id, role: user.role},SECRET, {expiresIn:'8h'});

		res.json({token, role: user.role});
		}
	);
});

// Middleware auth
function auth(req, res, next) {
  const header = req.headers.authorization;

  if (!header) return res.sendStatus(401);

  const token = header.split(" ")[1];

  try {
    const data = jwt.verify(token, SECRET);
    req.user = data;
    next();
  } catch {
    res.sendStatus(403);
  }
}

//Checking privileges
function isBoss(req, res, next) {
  if (req.user.role !== 'boss') {
    return res.status(403).send("Acceso denegado");
  }
  next();
}

function isAdminOrBoss(req, res, next) {
  if (req.user.role === 'admin' || req.user.role === 'boss') {
    return next();
  }

  return res.status(403).send("Acceso denegado");
}

//Cambiar contraseña
app.put('/user/profile', auth, async (req, res) => {
  const userId = req.user.userId;
  const { password } = req.body;

  if (!password || password.length < 6) {
    return res.status(400).send("La contraseña debe tener al menos 6 caracteres");
  }

  try {
    const hash = await bcrypt.hash(password, 10);

    db.run(
      `UPDATE users SET password = ? WHERE id = ?`,
      [hash, userId],
      function (err) {
        if (err) {
          console.error(err);
          return res.status(500).send("Error al actualizar contraseña");
        }

        if (this.changes === 0) {
          return res.status(404).send("Usuario no encontrado");
        }

        res.send("Contraseña actualizada");
      }
    );
  } catch (err) {
    res.status(500).send(err.message);
  }
});
// ================= DEVICES =================

// Añadir dispositivo (para pruebas)
app.post('/devices', auth, isAdminOrBoss, (req, res) => {
  const { name, ip, port } = req.body;

  db.run(
    `INSERT INTO devices (name, ip, port) VALUES (?, ?, ?)`,
    [name, ip, port],
    function (err) {
      if (err) return res.status(400).send(err.message);

      const deviceId = this.lastID;

      db.run(
        `INSERT INTO user_devices (user_id, device_id) VALUES (?, ?)`,
        [req.user.userId, deviceId]
      );

      res.send("Dispositivo añadido");
    }
  );
});

// Obtener dispositivos de tu usuario
app.get('/devices', auth, (req, res) => {
  db.all(
    `
    SELECT d.* FROM devices d
    JOIN user_devices ud ON d.id = ud.device_id
    WHERE ud.user_id = ?
  `,
    [req.user.userId],
    (err, rows) => {
      res.json(rows);
    }
  );
});

//Quitar dispositivo
app.delete('/devices/:id', auth, isBoss , (req, res) => {
  const deviceId = req.params.id;

  db.run(`DELETE FROM devices WHERE id = ?`, [deviceId]);
  db.run(`DELETE FROM user_devices WHERE device_id = ?`, [deviceId]);

  res.send("Eliminado");
});

//Ver todos los dispositivos
//app.get('/devices', auth, (req, res) => {

//  if (req.user.role === 'admin') {
//    db.all(`SELECT * FROM devices`, [], (err, rows) => {
//      return res.json(rows);
//    });
//  }

//  db.all(`
//    SELECT devices.* FROM devices
//    JOIN user_devices ON devices.id = user_devices.device_id
//    WHERE user_devices.user_id = ?
//  `, [req.user.id], (err, rows) => {
//    res.json(rows);
//  });
//});

// ================= USERS =================

//Obtener todos los dispositivos
app.get('/admin/devices', auth, isAdminOrBoss, (req, res) => {
  db.all(`SELECT * FROM devices`, [], (err, rows) => {
    res.json(rows);
  });
});

//Obtener dispositivos de 1 usuario
app.get('/admin/user-devices/:id', auth, isAdminOrBoss, (req, res) => {
  const userId = req.params.id;

  db.all(`
    SELECT devices.* FROM devices
    JOIN user_devices ON devices.id = user_devices.device_id
    WHERE user_devices.user_id = ?
  `, [userId], (err, rows) => {
    res.json(rows);
  });
});

//Añadir usuario
app.post('/admin/users', auth, isAdminOrBoss , async (req, res) => {
  const { username, password, role } = req.body;

  // VALIDACIONES
  if (!username || username.trim().length < 4) {
    return res.status(400).send("El usuario debe tener al menos 4 caracteres");
  }

  if (!password || password.length < 6) {
    return res.status(400).send("La contraseña debe tener al menos 6 caracteres");
  }

  try {
    const hash = await bcrypt.hash(password, 10);

    db.run(
      `INSERT INTO users (username, password, role) VALUES (?, ?, ?)`,
      [username, hash, role || 'user'],
      function (err) {
        if (err) {
          console.error(err);

          if (err.message.includes("UNIQUE")) {
            return res.status(400).send("El usuario ya existe");
          }

          return res.status(500).send("Error al crear usuario");
        }

        res.send("Usuario creado");
      }
    );
  } catch (err) {
    res.status(500).send(err.message);
  }
});

//Eliminar usuario
app.delete('/admin/users/:id', auth, isBoss, (req, res) => {
  const id = req.params.id;

  db.run(`DELETE FROM users WHERE id = ?`, [id]);
  db.run(`DELETE FROM user_devices WHERE user_id = ?`, [id]);

  res.send("Usuario eliminado");
});

//Asignar dispositivos a usuarios
app.post('/admin/assign', auth, isAdminOrBoss, (req, res) => {
  const { user_id, device_id } = req.body;

  db.run(
    `INSERT INTO user_devices (user_id, device_id) VALUES (?, ?)`,
    [user_id, device_id]
  );

  res.send("Asignado");
});

//Desasignar dispositivos a usuarios
app.post('/admin/unassign', auth, isAdminOrBoss , (req, res) => {
  const { user_id, device_id } = req.body;

  db.run(
    `DELETE FROM user_devices WHERE user_id = ? AND device_id = ?`,
    [user_id, device_id]
  );

  res.send("Desasignado");
});

//Ver todos los usuarios
app.get('/admin/users', auth, isAdminOrBoss, (req, res) => {
  db.all(`SELECT id, username, role FROM users`, [], (err, rows) => {
    res.json(rows);
  });
});

// ================= START =================

async function startServer() {

  try {

    await ensureBossUser();

    app.listen(3000, () => {
      console.log("Servidor corriendo en http://localhost:3000");
    });

  } catch (err) {

    console.error(err.message);
    process.exit(1);
  }
}

startServer();
