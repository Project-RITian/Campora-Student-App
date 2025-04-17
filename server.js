const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors()); // Enable CORS for Flutter app
app.use(express.json());

const dbConfig = {
  host: '192.168.0.2',
  port: 3306,
  user: 'root', // Replace with your MySQL username
  password: 'sidhu', // Replace with your MySQL password
  database: 'ritian'
};

app.get('/api/timetable-image/:classroomId', async (req, res) => {
  const classroomId = req.params.classroomId;
  let connection;

  try {
    connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT timetable_image_url FROM classrooms WHERE classroom_id = ?',
      [classroomId]
    );
    if (rows.length > 0) {
      res.json({ imageUrl: rows[0].timetable_image_url });
    } else {
      res.status(404).json({ error: 'Classroom not found' });
    }
  } catch (error) {
    console.error('Error fetching image URL:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (connection) await connection.end();
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});