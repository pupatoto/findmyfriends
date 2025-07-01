const  Pool  = require('pg').Pool;
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const app = express();
const fs = require('fs').promises;
const multer = require('multer');
const path = require('path');
const moment = require('moment');
const cron = require('node-cron');
const axios = require('axios');
const sgMail = require('@sendgrid/mail');
const { verify } = require('crypto');

app.use(bodyParser.json({ limit: '100mb' }));
app.use(bodyParser.urlencoded({ limit: '100mb', extended: true }))
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'Project',
    password: 'pupatoto1177995',
    port: 5432,
  });

const port = 3000;
app.use(express.json());
app.use('/postgroup', express.static(path.join(__dirname, 'upload')));
app.use('/editimageprofile', express.static(path.join(__dirname, 'profile_image')));
app.use('/addprofileimage', express.static(path.join(__dirname, 'profile_image')));
app.use('/sendimage', express.static(path.join(__dirname, 'chat')));
app.use('/sendimagedirect', express.static(path.join(__dirname, 'chat')));
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, 'upload'));
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 } 
});

const storageprofile = multer.diskStorage(
  {
    destination: (req, file, cb) => {
      cb(null, path.join(__dirname, 'profile_image'));
    },
    filename: (req, file, cb) => {
      cb(null, file.originalname);
    }
  }
)

const uploadProfile = multer({
  storage: storageprofile,
  limits: { fileSize: 50 * 1024 * 1024 } 
});

const storagechat = multer.diskStorage(
  {
    destination: (req, file, cb) => {
      cb(null, path.join(__dirname, 'chat'));
    },
    filename: (req, file, cb) => {
      cb(null, file.originalname);
    }
  }
)

const uploadChat = multer({
  storage: storagechat,
  limits: { fileSize: 50 * 1024 * 1024 } 
});

sgMail.setApiKey('SG.xxxxxx');

async function sendEmail(email, otp) {
  const msg = {
      to: email,
      from: 'teeratep.y@ku.th', 
      subject: 'Your OTP Code',
      text: `Your OTP code is: ${otp}`,
  };

  try {
    await sgMail.send(msg);
    console.log('Email sent successfully');
} catch (error) {
    console.error('Error sending email:', error.response ? error.response.body : error);
    throw new Error('Failed to send OTP email');
}
}

function generateRandomAlphanumericString(length) {
  const characterPool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let randomString = '';

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * characterPool.length);
    randomString += characterPool[randomIndex];
  }
  return randomString;
}

async function addAdmin(email, password) {
  const hashedPassword = await bcrypt.hash(password, 10); 

  const query = 'INSERT INTO admin (email, password) VALUES ($1, $2)';
  const values = [email, hashedPassword];

  try {
    const res = await pool.query(query, values);
    console.log('Admin added:', res);
  } catch (err) {
    console.error('Error adding admin:', err);
  }
}

app.post('/register', async (req, res) => {
  const { email, password, username } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiryTime = new Date(Date.now() + 2 * 60000);

  try {
      const emailCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      if (emailCheck.rows.length > 0) {
          return res.status(400).json({
              success: false,
              message: 'Email already in use'
          });
      }
      const usernameCheck = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
      if (usernameCheck.rows.length > 0) {
          return res.status(400).json({
              success: false,
              message: 'Username already in use'
          });
      }
      const hashedPassword = await bcrypt.hash(password, 10);
      await pool.query(
          `INSERT INTO users (email, password, username, otp, otp_expire) VALUES ($1, $2, $3, $4, $5)`,
          [email, hashedPassword, username, otp, expiryTime]
      );
      await sendEmail(email, otp);
      return res.status(201).json({ success: true, message: 'Register successful' });

  } catch (err) {
      console.error('Error registering user', err.stack);
      return res.status(500).json({ success: false });
  }
});

  
  app.post("/login", async (req, res) => {
    const { email, password } = req.body;

    try {
        const adminResult = await pool.query('SELECT * FROM admin WHERE email = $1', [email]);
        const isAdmin = adminResult.rows.length > 0;
        const userStatus = isAdmin ? adminResult.rows[0].status : null;

        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        const userData = result.rows[0];

        if (!userData && !isAdmin) {
            return res.status(400).json({ success: false, message: 'Please register' });
        }
        if (userData && !userData.verify) {
          return res.status(403).json({ success: false, message: 'Please verify your email before logging in' ,verify: false});
      }
        if (userData && userData.time_out && new Date(userData.time_out) > new Date()) {
            return res.status(403).json({ success: false, message: 'Your account has timeout.' });
        }

        if ((userData && userData.status === '0') ) {
            return res.status(403).json({ success: false, message: 'Your account has banned' });
        }

        const isMatch = isAdmin || (userData && await bcrypt.compare(password, userData.password));
        if (!isMatch) {
            return res.status(400).json({ success: false, message: 'Invalid email or password' });
        }

        const putData = userData && userData.gender && userData.birth_date && userData.age ? true : false;

        return res.status(200).json({
            success: true,
            message: 'Login successful',
            isAdmin: isAdmin,
            putData: putData
        });

    } catch (err) {
        console.error('Error logging in', err.stack);
        return res.status(500).json({ success: false, message: 'Error logging in' });
    }
});

app.post('/verify', async (req, res) => {
  const { email, otp } = req.body;
  try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1 AND otp = $2', [email, otp]);
      
      const userData = result.rows[0];
      if (!userData) {
          return res.status(400).json({ success: false, message: 'Invalid OTP' });
      }
      const isExpired = moment().isAfter(moment(userData.otp_expire));
      if (isExpired) {
          return res.status(400).json({ success: false, message: 'OTP has expired.' });
      }

      await pool.query('UPDATE users SET verify = $1 WHERE email = $2', [true, email]);

      res.status(200).json({ success: true, message: 'OTP verified successfully' });

  } catch (err) {
      console.error('Error verifying OTP', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});


app.post('/sendotp', async (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiryTime = new Date(Date.now() + 2 * 60000)
  try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const userData = result.rows[0];

      if (userData) {
        await pool.query('UPDATE users SET otp = $1 , otp_expire = $3 WHERE email = $2', [otp, email,expiryTime]);
          await sendEmail(email, otp);

          res.status(200).json({ success: true, message: 'OTP sent successfully' });
      } else {
          res.status(400).json({ success: false, message: 'Email not registered' });
      }
  } catch (err) {
      console.error('Error sending OTP', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/resend-otp', async (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiryTime = new Date(Date.now() + 2 * 60000)
  try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const userData = result.rows[0];

      if (userData) {
          await pool.query('UPDATE users SET otp = $1 , otp_expire = $3 WHERE email = $2', [otp, email,expiryTime]);

        
          await sendEmail(email, otp);

          res.status(200).json({ success: true, message: 'OTP sent successfully' });
      } else {
          res.status(400).json({ success: false, message: 'Email not registered' });
      }
  } catch (err) {
      console.error('Error sending OTP', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

  app.post("/currentuser", async (req, res) => {
    const { email } = req.body;
    try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const userData = result.rows[0];
      if (!userData) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      console.log('User data:', userData); 
      return res.status(200).json({ success: true, user: userData });
    } catch (err) {
      console.error('Error fetching user data', err.stack);
      return res.status(500).json({ success: false, message: 'Error fetching user data' });
    }
  });

  app.post('/postgroup', upload.array('image'), async (req, res) => {
    const { email, group_name, type_group, latitude, longitude, nameplace, date, time, age, gender, maxParticipants, Province } = req.body;
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'No images uploaded' });
    }
    
    const imageUrls = req.files.map(file => file.filename);
    const image_name = `{${imageUrls.join(',')}}`; 
    
    try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const userData = result.rows[0];
      
      if (!userData) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
  
      const groupCode = generateRandomAlphanumericString(5);

      await pool.query(
        'INSERT INTO create_group (email_owner, group_name, type_group, email_member, group_code, image_path, latitude, longitude, placename, date, time, age, gender, max_participants,province) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,$15)',
        [email, group_name, type_group, email, groupCode, image_name, latitude, longitude, nameplace, date, time, age, gender, maxParticipants,Province]
      );
  
      await pool.query(
        'INSERT INTO join_group (email_owner, group_name, type_group, email_member, group_code) VALUES ($1, $2, $3, $4, $5)',
        [email, group_name, type_group, email, groupCode]
      );
  
      console.log('User data:', userData);
      return res.status(200).json({ success: true, user: userData, message: 'Post group Success' });
    } catch (err) {
      console.error('Error fetching user data', err.stack);
      return res.status(500).json({ success: false, message: 'Error posting group' });
    }
});
  app.get('/viewgroup', async (req, res) => {
    try {
      const result = await pool.query(
        `SELECT g.group_name, g.email_owner, g.type_group, g.group_code, g.image_path, g.placename, g.date, g.time, g.age, g.gender,g.group_status,
                g.latitude, g.longitude, g.id_group,g.province,
                COUNT(j.email_member) AS participant_count,
                g.max_participants 
         FROM create_group g
         LEFT JOIN join_group j ON g.group_code = j.group_code
         GROUP BY g.group_name, g.email_owner, g.type_group, g.group_code, g.image_path, g.placename, g.date, g.time, g.age, g.gender, 
                  g.latitude, g.longitude, g.max_participants,g.group_status,g.id_group`
      );
  
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'No groups found' });
      }
  
      const userGroups = result.rows.map((row) => {
        const {
          group_name,
          email_owner,
          type_group,
          group_code,
          image_path,
          placename,
          date,
          time,
          age,
          gender,
          latitude,
          longitude,
          participant_count, 
          max_participants,
          group_status,
          id_group,
          province
        } = row;
  
        return {
          group_name,
          email_owner,
          type_group,
          group_code,
          image_path,
          placename,
          date,
          time,
          age,
          gender,
          latitude,
          longitude,
          participant_count, 
          max_participants,
          group_status,
          id_group,
          province  
        };
      });
  
      console.log(userGroups);
      return res.status(200).json({ success: true, userGroups });
    } catch (err) {
      console.error('Error fetching user group', err.stack);
      return res.status(500).json({ success: false, message: 'Error fetching user group' });
    }
  });
  
  app.post("/joingroup", async (req, res) => {
    const { email, group_name, type_group, group_code, email_member, action } = req.body;

    try {
        // ตรวจสอบว่าผู้ใช้มีอยู่ในระบบหรือไม่
        const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (!userResult.rows[0]) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // ดึงข้อมูลกลุ่มและจำนวนผู้เข้าร่วม
        const groupResult = await pool.query(
            'SELECT max_participants, COUNT(j.email_member) AS participant_count, age, gender, date FROM create_group g LEFT JOIN join_group j ON g.group_code = j.group_code WHERE g.group_code = $1 GROUP BY g.max_participants, g.age, g.gender, g.date',
            [group_code]
        );

        const groupData = groupResult.rows[0];
        if (!groupData) {
            return res.status(404).json({ success: false, message: 'Group not found' });
        }

        const { max_participants, participant_count, age, gender: allowed_gender, date: groupDate } = groupData;

        // แปลงประเภทข้อมูล
        const maxParticipants = parseInt(max_participants);
        const participantCount = parseInt(participant_count);

        // ตรวจสอบว่าค่าของ age และ gender ถูกกำหนดหรือไม่
        if (age === null || allowed_gender === null) {
            return res.status(400).json({ success: false, message: 'Age or gender requirement not defined' });
        }

        // แยกช่วงอายุออกเป็น min_age และ max_age
        const [min_age, max_age] = age.split('-').map(Number);

        // ดึงข้อมูลเพศและอายุของผู้ใช้
        const memberResult = await pool.query('SELECT username, gender, age, email FROM users WHERE email = $1', [email_member]);
        const memberData = memberResult.rows[0];
        if (!memberData) {
            return res.status(404).json({ success: false, message: 'Member not found' });
        }

        const { username, gender, age: memberAge } = memberData;

        // ตรวจสอบเงื่อนไขของกลุ่ม (เพศและอายุ)
        if (action === 'joingroup') {
            console.log(`User Email: ${email_member}, Group Code: ${group_code}, Action: ${action}`);
            console.log(`Participant Count: ${participantCount}, Max Participants: ${maxParticipants}`);

            // ตรวจสอบว่าจำนวนผู้เข้าร่วมเต็มหรือไม่
            if (participantCount >= maxParticipants) {
                return res.status(400).json({ success: false, message: 'Group is full, cannot join' });
            }

            // ตรวจสอบอายุของสมาชิก
            if (memberAge < min_age || memberAge > max_age) {
                return res.status(400).json({ success: false, message: 'Your age is not in range' });
            }

            // ตรวจสอบเงื่อนไขของเพศ
            if (!allowed_gender) {
                return res.status(400).json({ success: false, message: 'Gender requirement is not defined for this group' });
            }

            // แยกเพศที่อนุญาตออกเป็น array และตรวจสอบเพศ
            const allowedGenders = allowed_gender.split(',').map(g => g.trim().toLowerCase());
            if (!allowedGenders.includes(gender.toLowerCase())) {
                return res.status(400).json({ success: false, message: 'Your gender does not meet the group requirements' });
            }

            // ตรวจสอบว่าผู้ใช้เข้าร่วมกลุ่มในวันเดียวกันหรือไม่
            const dateCheck = await pool.query(
                `SELECT COUNT(*) AS count FROM join_group j
                JOIN create_group g ON j.group_code = g.group_code
                WHERE j.email_member = $1 AND g.date = $2`,
                [email_member, groupDate]
            );

            if (parseInt(dateCheck.rows[0].count) > 0) {
                return res.status(400).json({ success: false, message: 'You cannot join on same day' });
            }

            // เข้าร่วมกลุ่ม
            await pool.query(
                `INSERT INTO join_group (email_owner, group_name, type_group, email_member, group_code) VALUES ($1, $2, $3, $4, $5)`,
                [email, group_name, type_group, email_member, group_code]
            );

            const message = `${username} has joined the group ${group_name}.`;
            await pool.query(
                `INSERT INTO notifications (email_owner, group_name, user_email, group_code, message) VALUES ($1, $2, $3, $4, $5)`,
                [email, group_name, email_member, group_code, message]
            );

            return res.status(200).json({ success: true, message: 'Successfully joined the group' });
        }

        if (action === 'leavegroup') {
            await pool.query(
                `DELETE FROM join_group WHERE email_owner = $1 AND group_name = $2 AND email_member = $3`,
                [email, group_name, email_member]
            );
            return res.status(200).json({ success: true, message: 'Successfully left the group' });
        }
    } catch (err) {
        console.error('Error handling group status', err.stack);
        return res.status(500).json({ success: false, message: 'Error handling group status' });
    }
});


app.post("/viewyourpostgroup", async (req, res) => {
  const { email } = req.body;
  try {
    const result = await pool.query(`
      SELECT 
        c.group_name,
        c.email_owner,
        c.type_group,
        c.group_code,
        c.image_path,
        c.latitude,
        c.longitude,
        c.placename,
        c.date,
        c.time,
        c.age,
        c.gender,
        c.max_participants,
        c.id_group,
        c.group_status,
        COUNT(j.email_member) AS participant_count  
      FROM 
        create_group AS c
      LEFT JOIN 
        join_group AS j ON c.group_code = j.group_code
      WHERE 
        c.email_owner = $1
      GROUP BY 
        c.group_name, c.email_owner, c.type_group, c.group_code,
        c.image_path, c.latitude, c.longitude, c.placename,
        c.date, c.time, c.age, c.gender, c.max_participants, c.group_status, c.id_group
    `, [email]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User is not a member of any group' });
    }

    const userGroups = result.rows.map(row => ({
      group_name: row.group_name,
      email_owner: row.email_owner,
      type_group: row.type_group,
      group_code: row.group_code,
      image_path: row.image_path,
      latitude: row.latitude,
      longitude: row.longitude,
      placename: row.placename,
      date: row.date,
      time: row.time,
      age: row.age,
      gender: row.gender,
      max_participants: row.max_participants,
      participant_count: parseInt(row.participant_count) || 0, 
      group_status: row.group_status,
      id_group: row.id_group
    }));
    
    console.log(userGroups);
    return res.status(200).json({ success: true, userGroups });
  } catch (err) {
    console.error('Error fetching user group', err.stack);
    return res.status(500).json({ success: false, message: 'Error fetching userjoingroup' });
  }
});

app.post("/viewjoingroup", async (req, res) => {
  const { email } = req.body;
  try {
    const result = await pool.query(
      `
      SELECT 
        c.group_name,
        c.id_group,
        c.email_owner,
        c.type_group,
        c.group_code,
        c.image_path,
        c.latitude,
        c.longitude,
        c.placename,
        c.date,
        c.time,
        c.age,
        c.gender,
        c.max_participants,
        c.group_status,
        COUNT(j.email_member) AS participant_count
      FROM 
        create_group AS c
      LEFT JOIN 
        join_group AS j ON c.group_code = j.group_code
      GROUP BY 
        c.group_name, c.email_owner, c.type_group, c.group_code,
        c.image_path, c.latitude, c.longitude, c.placename,
        c.date, c.time, c.age, c.gender, c.max_participants,
        c.group_status ,c.id_group
      HAVING 
        SUM(CASE WHEN j.email_member = $1 THEN 1 ELSE 0 END) > 0
      `,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User is not a member of any group",
      });
    }

    const userGroups = result.rows.map((row) => ({
      group_name: row.group_name,
      email_owner: row.email_owner,
      type_group: row.type_group,
      group_code: row.group_code,
      image_path: row.image_path,
      latitude: row.latitude,
      longitude: row.longitude,
      placename: row.placename,
      date: row.date,
      time: row.time,
      age: row.age,
      gender: row.gender,
      max_participants: row.max_participants,
      group_status: row.group_status, 
      participant_count: parseInt(row.participant_count) || 0, 
      id_group: row.id_group
    }));

    console.log(userGroups);
    return res.status(200).json({ success: true, userGroups });
  } catch (err) {
    console.error("Error fetching user group", err.stack);
    return res
      .status(500)
      .json({ success: false, message: "Error fetching userjoingroup" });
  }
});


app.post("/deletegroup", async (req, res) => {
  const { group_code } = req.body;
  try {
    const groupResult = await pool.query(
      `SELECT group_status, email_owner FROM create_group WHERE group_code = $1`,
      [group_code]
    );

    if (groupResult.rows.length > 0) {
      const groupStatus = groupResult.rows[0].group_status; 
      const emailOwner = groupResult.rows[0].email_owner;

      if (groupStatus === '0') {
        await pool.query(
          `UPDATE users SET credits = CAST(credits AS INTEGER) - 2 WHERE email = $1`,
          [emailOwner]
        );
      }
      await pool.query(`DELETE FROM create_group WHERE group_code = $1`, [group_code]);
      await pool.query(`DELETE FROM join_group WHERE group_code = $1`, [group_code]);
      await pool.query(`DELETE FROM comment WHERE group_code = $1`, [group_code]);
      await pool.query(`DELETE FROM like_group WHERE group_like = $1`, [group_code]);
      await pool.query(`DELETE FROM group_report WHERE group_code = $1`, [group_code]);

      return res.status(200).json({ success: true, message: 'Deleting group success' });
    } else {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }
  } catch (error) {
    console.error('Error deleting group', error.stack);
    return res.status(500).json({ success: false, message: 'Error deleting group' });
  }
});

  app.post("/likegroup", async (req, res) => {
    const { email_like, group_code, action } = req.body;
    try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email_like]);
      const userData = result.rows[0];
  
      if (!userData) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      if (action === 'unlikegroup') {
        await pool.query(`DELETE FROM like_group WHERE email_like = $1 AND group_like = $2`, [email_like, group_code]);
        return res.status(200).json({ success: true, message: 'Successfully unliked the group' });
      } else if (action === 'likegroup') {
        await pool.query(`INSERT INTO like_group (email_like, group_like) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [email_like, group_code]);
        return res.status(200).json({ success: true, message: 'Successfully liked the group' });
      } else {
        return res.status(400).json({ success: false, message: 'Invalid action' });
      }
    } catch (error) {
      console.error('Error handling like group', error.stack);
      return res.status(500).json({ success: false, message: 'Error handling like group' });
    }
  });

  app.post("/addcomment",async (req,res) =>{
    const { email,group_code,comment_text,timestamp} = req.body;
    try{
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        const userData = result.rows[0];
        if (!userData) {
          return res.status(404).json({ success: false, message: 'User not found' });
        }
        await pool.query(`INSERT INTO comment (email, group_code,comment_text,timestamp) VALUES ($1, $2,$3,$4) ON CONFLICT DO NOTHING`, [email, group_code,comment_text,timestamp]);
        return res.status(200).json({ success: true, message: 'Successfully comment the group' });
    }catch(error){
      console.error('Error handling like group', error.stack);
      return res.status(500).json({ success: false, message: 'Error comment' });
    }
  } )
  
  app.get('/getcomment', async (req, res) => {
    const { group_code } = req.query;
    try {
      const result = await pool.query(`
        SELECT c.*, u.username, u.profile_image 
        FROM comment c
        JOIN users u ON c.email = u.email
        WHERE c.group_code = $1
      `, [group_code]);
  
      res.json({ success: true, comments: result.rows });
    } catch (error) {
      console.error('Error fetching comments:', error.stack);
      res.status(500).json({ success: false, message: 'Error fetching comments' });
    }
  });
  
  
  app.post('/deletecomment',async (req,res)=>{
    const {comment_id} = req.body;
    try {
      await pool.query(`DELETE FROM comment WHERE comment_id = $1`, [comment_id]);
      return res.status(200).json({ success: true,message: 'deleting comment success' });
    } catch (error) {
      console.error('Error deleting group', error.stack);
      return res.status(500).json({ success: false, message: 'Error deleting comment' });
    }
  })

  app.post('/editcomment',async (req,res)=>{
    const {comment_id,comment_text} = req.body;
    try {
      await pool.query(`UPDATE comment SET comment_text = $1 WHERE comment_id = $2`,
      [comment_text, comment_id]);
      return res.status(200).json({ success: true,message: 'Update comment success' });
    } catch (error) {
      return res.status(500).json({ success: false, message: 'Error update comment' });
    }
  })

  app.get('/getmembergroup', async (req, res) => {
    const { group_code } = req.query;
    try {
        const result = await pool.query(`
            SELECT j.email_member, j.email_owner, u.username, u.profile_image, j.join_status
            FROM join_group AS j
            JOIN users AS u ON j.email_member = u.email
            WHERE j.group_code = $1
        `, [group_code]);
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'No members found for this group.' });
        }

        res.json({ success: true, participants: result.rows });
    } catch (error) {
        console.error('Error fetching participants:', error.stack);
        res.status(500).json({ success: false, message: 'Error fetching participants' });
    }
});

app.get('/getnotifications', async (req, res) => {
  const { email } = req.query;
  try {
    const groupNotifications = await pool.query(`
      SELECT 
        n.noti_id, 
        n.message, 
        n.user_email AS user_email, 
        n.created_at, 
        u.username, 
        u.profile_image,
        g.*, 
        'group' AS type
      FROM notifications AS n
      JOIN users AS u ON n.user_email = u.email
      JOIN create_group AS g ON n.group_code = g.group_code
      WHERE n.email_owner = $1 
      ORDER BY n.created_at DESC
    `, [email]);

    const friendNotifications = await pool.query(`
      SELECT 
        f.notif_id, 
        f.message,  
        f.created_at,
        u.username, 
        u.profile_image,
        u.email  AS user_email,
        'friend' AS type 
      FROM friend_notifications AS f
      JOIN users AS u ON f.receiver_email = u.email
      WHERE f.sender_email = $1
      ORDER BY f.created_at DESC
    `, [email]);

    const endGroupNotifications = await pool.query(`
      SELECT 
        ngs.notig_id, 
        ngs.message, 
        ngs.email_member AS user_email,
        ngs.group_code,
        ngs.created_at,
        g.*,
        'groupend' AS type
      FROM notificationgroupstatus AS ngs
      JOIN create_group AS g ON ngs.group_code = g.group_code
      WHERE ngs.email_member = $1 
      ORDER BY ngs.created_at DESC
    `, [email]);

    const notifications = [
      ...groupNotifications.rows,
      ...friendNotifications.rows,
      ...endGroupNotifications.rows
    ];

    if (notifications.length > 0) {
      return res.status(200).json({ success: true, notifications });
    } else {
      return res.status(200).json({ success: true, message: 'No notifications found', notifications: [] });
    }
  } catch (err) {
    console.error('Error retrieving notifications', err.stack);
    return res.status(500).json({ success: false, message: 'Error retrieving notifications' });
  }
});


app.post('/deletenotifications', async (req, res) => {
  const { id, type } = req.body; 
  try {
    let result;
    if (type === 'group') {
      result = await pool.query('DELETE FROM notifications WHERE noti_id = $1', [id]); 
    } else if (type === 'friend') {
      result = await pool.query('DELETE FROM friend_notifications WHERE notif_id = $1', [id]);
    }else {
      result = await pool.query('DELETE FROM notificationgroupstatus WHERE notig_id = $1', [id]);
    }
    
    if (result.rowCount > 0) {
      return res.status(200).json({ message: 'Notification deleted successfully' });
    } else {
      return res.status(404).json({ message: 'Notification not found' });
    }
  } catch (err) {
    console.error('Error deleting notifications', err.stack);
    return res.status(500).json({ message: 'Error deleting notification' });
  }
});

app.post('/editprofile', async (req, res) => {
  const { username, email, id, birthdate, gender, age } = req.body;

  try {
    const usernameCheck = await pool.query(
      `SELECT user_id FROM users WHERE username = $1 AND user_id != $2`,
      [username, id]
    );

    if (usernameCheck.rowCount > 0) {
      return res.status(409).json({
        success: false,
        message: 'Username is already Used',
      });
    }

    const result = await pool.query(
      `UPDATE users SET username = $1, email = $2, birth_date = $3, age = $4, gender = $5 WHERE user_id = $6`,
      [username, email, birthdate, age, gender, id]
    );

    if (result.rowCount > 0) {
      res.status(200).json({ success: true, message: 'Update successful' });
    } else {
      res.status(404).json({ success: false, message: 'User not found' });
    }
  } catch (error) {
    console.error('Error updating profile:', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/addprofileimage', uploadProfile.single('profileImage'), async (req, res) =>{
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image uploaded' });
  }
  
  const image_name = req.file.filename;
  const email = req.body.email;

  try {
    await pool.query(
      'UPDATE users SET profile_image = $1 WHERE email = $2',
      [image_name, email]
    );

    res.status(200).json({ success: true, message: 'Profile image updated successfully' });
  } catch (error) {
    console.error('Database update error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile image' });
  }

  
})

app.post('/editimageprofile', uploadProfile.single('profileImage'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image uploaded' });
  }
  
  const image_name = req.file.filename;
  const userId = req.body.userId;

  try {
    await pool.query(
      'UPDATE users SET profile_image = $1 WHERE user_id = $2',
      [image_name, userId]
    );

    res.status(200).json({ success: true, message: 'Profile image updated successfully' });
  } catch (error) {
    console.error('Database update error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile image' });
  }
});
app.post('/deleteimageprofile', async (req, res) => {
  const { id } = req.body;
  try {
    await pool.query(`UPDATE users SET profile_image = NULL WHERE user_id = $1`, [id]);
    return res.status(200).json({ success: true, message: 'Profile Image deleted successfully' });
  } catch (err) {
    console.error('Error deleting profile image:', err.stack);
    return res.status(500).json({ success: false, message: 'Error deleting Profile Image' });
  }
});

app.post('/putdataprofile', async (req, res) => {
  const { email, birthdate, gender, age } = req.body;

  try {
    const result  =await pool.query(`UPDATE users SET birth_date = $1, gender = $2, age = $3 WHERE email = $4
    `,[birthdate, gender, age, email]) ;
 

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.status(200).json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Error updating profile:', error);
    return res.status(500).json({ success: false, message: 'Error updating profile' });
  }
});

app.post('/getlikegroup', async (req, res) => {
  const { email } = req.body;
  try {
    const result = await pool.query(
      `SELECT 
        cg.group_name, 
        cg.type_group, 
        cg.image_path, 
        cg.latitude, 
        cg.longitude, 
        cg.placename, 
        cg.date, 
        cg.time, 
        cg.age, 
        cg.gender, 
        cg.max_participants, 
        cg.email_owner, 
        cg.group_code,
        cg.group_status,
        cg.id_group,
        COUNT(jg.email_member) AS participant_count
       FROM 
        create_group cg 
       JOIN 
        like_group lg ON cg.group_code = lg.group_like
       LEFT JOIN 
        join_group jg ON cg.group_code = jg.group_code
       WHERE 
        lg.email_like = $1
       GROUP BY 
        cg.group_name, 
        cg.type_group, 
        cg.image_path, 
        cg.latitude, 
        cg.longitude, 
        cg.placename, 
        cg.date, 
        cg.time, 
        cg.age, 
        cg.gender, 
        cg.max_participants, 
        cg.email_owner, 
        cg.group_code,
        cg.group_status,
        cg.id_group
      `,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'No liked groups found' });
    }

    const likedGroups = result.rows.map((row) => ({
      group_name: row.group_name,
      type_group: row.type_group,
      image_path: row.image_path,
      latitude: row.latitude,
      longitude: row.longitude,
      placename: row.placename,
      date: row.date,
      time: row.time,
      age: row.age,
      gender: row.gender,
      max_participants: row.max_participants,
      email_owner: row.email_owner,
      group_code: row.group_code,
      group_status: row.group_status,
      participant_count: parseInt(row.participant_count) || 0, 
      id_group: row.id_group
    }));

    return res.status(200).json({ success: true, likedGroups });

  } catch (error) {
    console.error('Error fetching GroupLike', error.stack);
    return res.status(500).json({ success: false, message: 'Error fetching GroupLike' });
  }
});

app.post('/checkin',async (req,res)=> {
const {email,groupCode} = req.body;
try {
  const result = await pool.query(
    `UPDATE join_group SET join_status=1 WHERE email_member = $1 AND group_code = $2` ,
    [email,groupCode]
  );
  if (result.rowCount > 0) {
    res.status(200).json({ success: true, message: 'Checkin successful' });
  } else {
    res.status(404).json({ success: false, message: 'Checkin failed' });
  }
} catch (error) {
  console.error('Error updating profile:', error.stack);
  res.status(500).json({ success: false, message: 'server error' });
}
})

app.post('/endgroup', async (req, res) => {
  const { groupcode } = req.body;
  try {
    const result = await pool.query(
      `UPDATE create_group SET group_status=1 WHERE group_code = $1`,
      [groupcode]
    );

    if (result.rowCount > 0) {
      const data = await pool.query(
        `SELECT cg.group_name, cg.email_owner, jg.email_member 
         FROM create_group cg
         LEFT JOIN join_group jg ON cg.group_code = jg.group_code
         WHERE cg.group_code = $1`,
        [groupcode]
      );

      const groupname = data.rows[0].group_name;
      const owner = data.rows[0].email_owner;
      const message = `${groupname} has ended. Please give a score for the Creator.`;

      for (const row of data.rows) {
        const member = row.email_member;
        if (member && member !== owner) {
          await pool.query(
            `INSERT INTO notificationgroupstatus (group_name,email_member, group_code, message) 
             VALUES ($1, $2, $3, $4)`,
            [groupname, member, groupcode, message]
          );
        }
      }

      res.status(200).json({ success: true, message: 'End Group successful and notifications sent' });
    } else {
      res.status(404).json({ success: false, message: 'End Group failed' });
    }
  } catch (error) {
    console.error('Error ending group and sending notifications:', error.stack);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

  app.post('/fetchjoinstatus', async (req, res) => {
    const { email, groupcode } = req.body;
    try {
        const result = await pool.query(
            'SELECT join_status FROM join_group WHERE email_member = $1 AND group_code = $2',
            [email, groupcode]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Join status not found' });
        }

        const joinStatus = result.rows[0].join_status;
        return res.status(200).json({ success: true, join_status: joinStatus });
    } catch (err) {
        console.error('Error fetching join status:', err.message);
        return res.status(500).json({ success: false, message: 'Error fetching join status' });
    }
});

app.post('/updatecredits', async (req, res) => {
  const { groupCode } = req.body;

  try {
    const { rows } = await pool.query(
      `SELECT j.join_status, j.email_member, u.credits, g.group_status
      FROM join_group AS j
      JOIN users AS u ON j.email_member = u.email
      JOIN create_group AS g ON j.group_code = g.group_code
      WHERE j.group_code = $1`,
      [groupCode]
    );

    if (rows.length > 0) {
      const membersToDeduct = rows.filter(member => member.join_status === '0' && member.group_status === '1');
      const membersToAdd = rows.filter(member => member.join_status === '1' && member.group_status === '1');

      if (membersToDeduct.length > 0) {
        for (const member of membersToDeduct) {
          const updatedCredits = Math.max(Number(member.credits) - 1, 0); 
          await pool.query(
            'UPDATE users SET credits = $1 WHERE email = $2',
            [updatedCredits, member.email_member]
          );
        }
      }

      if (membersToAdd.length > 0) {
        for (const member of membersToAdd) {
          const updatedCredits = Number(member.credits) + 1;
          await pool.query(
            'UPDATE users SET credits = $1 WHERE email = $2',
            [updatedCredits, member.email_member]
          );
        }
      }
      res.status(200).json({
        success: true,
        message: 'Credits updated successfully',
        updatedMembers: {
          deducted: membersToDeduct.map(member => member.email_member),
          added: membersToAdd.map(member => member.email_member)
        }
      });
    } else {
      res.status(404).json({ success: false, message: 'Data not found for this group' });
    }
  } catch (error) {
    console.error('Error updating credits:', error);
    res.status(500).json({ success: false, message: 'Failed to update credits' });
  }
});

app.get('/getgroupowner', async (req, res) => {
  const { group_code } = req.query;
  try {
      const result = await pool.query(`
          SELECT u.email, u.username, u.profile_image, j.join_status
          FROM create_group AS g
          JOIN users AS u ON g.email_owner = u.email
          JOIN join_group AS j ON g.group_code = j.group_code AND g.email_owner = j.email_member
          WHERE g.group_code = $1
      `, [group_code]);

      if (result.rows.length === 0) {
          return res.status(404).json({ success: false, message: 'Owner not found for this group.' });
      }

      res.json({ success: true, owner: result.rows[0] });
  } catch (error) {
      console.error('Error fetching group owner:', error.stack);
      res.status(500).json({ success: false, message: 'Error fetching group owner' });
  }
});

app.get('/getallusers', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users');
    res.status(200).json(result.rows); 
  } catch (error) {
    console.error('Error retrieving users:', error); 
    res.status(500).json({ error: 'Failed to get users' });
  }
});

app.post('/banuser',async (req, res)=> {
  const {userId} = req.body 
  try {
    await pool.query('UPDATE users SET status = 0 WHERE user_id = $1', [userId]);
    res.status(200).send({ message: 'User banned successfully' });
  } catch (error) {
    res.status(500).send({ error: 'Failed to ban user' });
  }
})

app.post('/unbanuser', async (req, res) => {
  const {userId} = req.body
  try {
    await pool.query('UPDATE users SET status = 1 WHERE user_id = $1', [userId]);
    res.status(200).send({ message: 'User Unbanned successfully' });
  } catch (error) {
    res.status(500).send({ error: 'Failed to Unban user' });
  }
})

app.post('/timeout', async (req, res) => {
  const { userId, duration } = req.body; 
  try {
    const timeoutDuration = duration * 1000; 
    const timeoutUntil = new Date(Date.now() + timeoutDuration);

    await pool.query('UPDATE users SET time_out = $1 WHERE user_id = $2', [timeoutUntil, userId]);

    res.status(200).json({ success: true, message: 'User has been timed out.', timeoutUntil });
  } catch (error) {
    console.error('Error setting timeout:', error);
    res.status(500).json({ success: false, message: 'Error setting timeout.' });
  }
});

app.post('/reportuser', async (req, res) => {
  const { email, messages } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO user_report (email, messages) VALUES ($1, $2)', 
      [email, messages]
    );
    res.status(200).json({ message: 'Report submitted successfully' }); 
  } catch (error) {
    console.error('Error inserting report:', error);
    res.status(500).json({ message: 'Report submitted Failed' });
  }
});

app.get('/getreportsuser', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT ur.*, u.username, u.profile_image 
      FROM user_report ur
      JOIN users u ON ur.email = u.email
    `);
    res.status(200).json(result.rows); 
  } catch (error) {
    console.error('Error fetching reports:', error);
    res.status(500).json({ message: 'Failed to retrieve reports' });
  }
});

app.post('/deletereportuser',async (req,res) => {
  const {id} = req.body;
  try {
    await pool.query(`DELETE FROM user_report WHERE reportu_id = $1`, [id]);
    return res.status(200).json({ success: true,message: 'deleting report success' });
  } catch (error) {
    console.error('Error deleting group', error.stack);
    return res.status(500).json({ success: false, message: 'Error deleting report' });
  }
 })

app.post('/reportgroup', async (req, res) => {
  const { groupCode } = req.body;
  try {
    if (!groupCode) {
      return res.status(400).json({ success: false, message: 'Group code is required' });
    }
    await pool.query(`INSERT INTO group_report (group_code) VALUES ($1)`, [groupCode]);
    res.status(200).json({ success: true, message: 'Group reported successfully' });
  } catch (error) {
    console.error('Error reporting group:', error);
    res.status(500).json({ success: false, message: 'Error reporting group' });
  }
});

app.get('/getgroupreport', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        cg.*, 
        (SELECT COUNT(*) FROM group_report gr WHERE gr.group_code = cg.group_code) AS report_count, 
        COUNT(DISTINCT jg.email_member) AS participant_count 
      FROM 
        create_group cg 
      LEFT JOIN 
        join_group jg ON cg.group_code = jg.group_code  
      WHERE 
        (SELECT COUNT(*) FROM group_report gr WHERE gr.group_code = cg.group_code) > 0
      GROUP BY 
        cg.id_group, 
        cg.group_name, 
        cg.group_code, 
        cg.type_group, 
        cg.placename, 
        cg.date, 
        cg.time, 
        cg.age, 
        cg.gender, 
        cg.image_path
    `);
    
    console.log("Query Result:", result.rows);
    
    res.status(200).json({ 
      success: true, 
      data: result.rows, 
      message: 'Get group reported successfully' 
    });
  } catch (error) {
    console.error('Error getting reported group:', error);
    res.status(500).json({ success: false, message: 'Error getting reported group' });
  }
});

app.post("/deletegroupfromadmin", async (req, res) => {
  const { group_code } = req.body;
  try {
    await pool.query(`DELETE FROM create_group WHERE group_code = $1`, [group_code]);
    await pool.query(`DELETE FROM join_group WHERE group_code = $1`, [group_code]);
    await pool.query(`DELETE FROM comment WHERE group_code = $1`, [group_code]);
    await pool.query(`DELETE FROM group_report WHERE group_code = $1`, [group_code]);
    await pool.query(`DELETE FROM like_group WHERE group_like = $1`, [group_code]);
    return res.status(200).json({ success: true,message: 'deleting group success' });
  } catch (error) {
    console.error('Error deleting group', error.stack);
    return res.status(500).json({ success: false, message: 'Error deleting group' });
  }
});

app.post('/deletereport',async (req,res) => {
  const {group_code} = req.body;
  try {
    await pool.query(`DELETE FROM group_report WHERE group_code = $1`, [group_code]);
    return res.status(200).json({ success: true,message: 'deleting report success' });
  } catch (error) {
    console.error('Error deleting group', error.stack);
    return res.status(500).json({ success: false, message: 'Error deleting report' });
  }
 })

app.post('/addfriend', async (req, res) => {
  const { sender_email, receive_email } = req.body;
  try {
        await pool.query('INSERT INTO friends_request (sender_email,receive_email) VALUES ($1, $2)', [sender_email, receive_email]);
      res.status(200).json({ success: true, message: 'Friend request sent successfully' });
  } catch (err) {
      console.error('Error sending friend request', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/removeaddfriend', async (req, res) => {
  const { sender_email, receive_email } = req.body;
  try {

    await pool.query(
      `DELETE FROM friends_request WHERE sender_email = $1 AND receive_email = $2`,
      [sender_email, receive_email]
    );

    res.status(200).json({ success: true, message: 'Friend request and chat history deleted successfully' });
  } catch (err) {
    console.error('Error deleting friend request and chat history', err.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/getfriendsrequest', async (req, res) => {
  const { email } = req.query;
  try {
    const result = await pool.query(`
      SELECT u.username, u.profile_image, fr.sender_email,fr.add_id,fr.status
      FROM friends_request fr
      JOIN users u ON u.email = fr.sender_email
      WHERE fr.receive_email = $1
    `, [email]);

    res.status(200).json({ success: true, data: result.rows, message: "Friend's request fetched successfully" });
  } catch (error) {
    console.error('Error fetching friend request:', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/acceptfriends', async (req, res) => {
  const { email, email_friends, add_id } = req.body;
  try {
    await pool.query('INSERT INTO friends (email, email_friends) VALUES ($1, $2)', [email, email_friends]);
    await pool.query('INSERT INTO friends (email, email_friends) VALUES ($1, $2)', [email_friends, email]);
    const result = await pool.query('SELECT username FROM users WHERE email = $1', [email]);
    const username = result.rows[0].username;
    await pool.query(`UPDATE friends_request SET status = '2' WHERE add_id = $1`, [add_id]);

    const message = `${username} has accept request`;
      await pool.query(
        `INSERT INTO friend_notifications (sender_email,receiver_email,message) VALUES ($1, $2, $3)`,
        [email_friends, email,message]
      ); 

    res.status(200).json({ success: true, message: "Friend accepted successfully" });
  } catch (error) {
    console.error('Error accepting friend request:', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/rejectfriends', async (req, res) => {
  const {add_id} = req.body;
  try {
    await pool.query(`DELETE FROM friends_request WHERE add_id = $1`, [add_id]);
    res.status(200).json({ success: true, message: "Friend reject successfully" });
  } catch (error) {
    console.error('Error rejecting friend request:', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
})

app.get('/getallusersadd', async (req, res) => {
  const { email } = req.query; 
  try {
    const query = `
      SELECT u.email, u.username, u.profile_image, fr.status 
      FROM users u
      LEFT JOIN friends_request fr
      ON (u.email = fr.receive_email AND fr.sender_email = $1)
      OR (u.email = fr.sender_email AND fr.receive_email = $1)
    `;
    const result = await pool.query(query, [email]);
    console.log(result.rows);
    res.status(200).json(result.rows);
  } catch (err) {
    console.error('Error fetching users', err.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/checkfriendstatus', async (req, res) => {
  const { sender_email, receive_email } = req.body;
  try {
    const result = await pool.query(
      'SELECT status FROM friends_request WHERE (sender_email = $1 AND receive_email = $2) OR (sender_email = $2 AND receive_email = $1)',
      [sender_email, receive_email]
    );

    if (result.rows.length > 0) {
      res.status(200).json({ success: true, status: result.rows[0].status });
    } else {
      res.status(200).json({ success: true, status: null });
    }
  } catch (error) {
    console.error('Error fetching Addfriend Status', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/removefriends', async (req, res) => {
  const { sender_email, receive_email } = req.body;
  try {
    await pool.query(
      `DELETE FROM friends_request WHERE (sender_email = $1 AND receive_email = $2) OR (sender_email = $2 AND receive_email = $1)`,
      [sender_email, receive_email]
    );
    
    await pool.query(
      `DELETE FROM friends WHERE (email = $1 AND email_friends = $2) OR (email = $2 AND email_friends = $1)`,
      [sender_email, receive_email]
    );

    await pool.query(
      `DELETE FROM messagesdirect 
       WHERE (sender_email = $1 AND receiver_email = $2) 
          OR (sender_email = $2 AND receiver_email = $1)`,
      [sender_email, receive_email]
    );

    res.status(200).json({ success: true, message: 'Friend removed successfully' });
  } catch (error) {
    console.error('Error removing friend', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/getfriendslist', async (req, res) => {
  const { email } = req.query;
  try {
    const friendsResult = await pool.query(
      `
      SELECT f.email_friends, u.username, u.profile_image
      FROM friends f
      JOIN users u ON f.email_friends = u.email
      WHERE f.email = $1
      `,
      [email]
    );

    const countResult = await pool.query(
      `SELECT COUNT(*) FROM friends WHERE email = $1`,
      [email]
    );
    const friendsCount = parseInt(countResult.rows[0].count, 10);

    if (friendsResult.rows.length > 0) {
      res.status(200).json({
        success: true,
        message: 'Get friends successfully',
        friends: friendsResult.rows,
        friendsCount: friendsCount,  
      });
    } else {
      res.status(200).json({
        success: true,
        message: 'No friends found',
        friends: [],
        friendsCount: 0,  
      });
    }
  } catch (error) {
    console.error('Error getting friends', error.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/groupjoinchat', async (req, res) => {
  const { email } = req.body;
  try {
    const result = await pool.query(
      `
      SELECT 
      c.id_group, 
      c.group_name, 
      c.image_path,
      c.group_code,
      c.group_status,
      COALESCE(m.message, 'No Message') AS latest_message,
      COALESCE(m.sender_email, '') AS sender_email,
      COALESCE(u.username, '') AS sender_username,
      COALESCE(m.time, NOW()) AS latest_time,
      COALESCE(m.message_type, 'text') AS message_type
      FROM 
      create_group AS c
      JOIN 
      join_group AS j ON c.group_code = j.group_code
      LEFT JOIN 
      messagesgroup AS m ON c.id_group = m.group_id
      LEFT JOIN 
      users AS u ON m.sender_email = u.email
      WHERE 
      j.email_member = $1
      AND 
      (m.time IS NULL OR m.time = (
        SELECT MAX(time) 
        FROM messagesgroup 
        WHERE group_id = c.id_group
      ))
      GROUP BY c.id_group, m.message, m.sender_email, u.username, m.time, m.message_type,c.group_status
      ORDER BY latest_time DESC;
      `,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User is not a member of any group' });
    }

    const groupsList = result.rows.map(row => ({
      id_group: row.id_group,
      group_name: row.group_name,
      image_path: row.image_path,
      latest_message: row.latest_message,
      sender_email: row.sender_email,
      sender_username: row.sender_username,
      latest_time: row.latest_time,
      message_type: row.message_type,
      group_status:row.group_status,
    }));

    res.status(200).json({ success: true, groups: groupsList });
  } catch (error) {
    console.error("Error fetching chat groups:", error.message);
    res.status(500).json({ error: 'Error fetching chat groups.' });
  }
});


app.post('/sendmessage', async (req, res) => {
  const { groupId, sender, message } = req.body;
  try {
    await pool.query('INSERT INTO messagesgroup (group_id, sender_email, message, time) VALUES ($1, $2, $3, NOW())', 
    [groupId, sender, message]);
    res.status(201).json({ message: 'Message sent successfully' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

app.get('/getmessages', async (req, res) => {
  const { groupId } = req.query;
  try {
    const result = await pool.query(`
      SELECT 
        m.message,
        m.time,
        u.username,
        u.profile_image ,
        m.sender_email,
        m.message_type,
        m.messagesg_id,
        m.imageurl
      FROM 
        messagesgroup m
      JOIN 
        users u 
      ON 
        m.sender_email = u.email
      WHERE 
        m.group_id = $1
      ORDER BY 
        m.time ASC
    `, [groupId]);
    
    res.status(200).json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

app.post('/getLatestMessages', async (req, res) => {
  try {
      const result = await pool.query(`
          SELECT mg.group_id, mg.message, mg.time, u.username,u.email
          FROM messagesgroup mg
          JOIN users u ON mg.sender_email = u.email
          WHERE mg.time = (
              SELECT MAX(time)
              FROM messagesgroup
              WHERE group_id = mg.group_id
          )
      `);
      res.json(result.rows);
  } catch (error) {
      console.error(error);
      res.status(500).send('Error retrieving latest messages');
  }
});

app.post('/sendimage', uploadChat.array('sendimage'), async (req, res) => {
  const { groupId, sender_email } = req.body;

  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

  const imageUrls = req.files.map(file => file.filename); 
  const Image = `{${imageUrls.join(',')}}`;  
  try {
    await pool.query(
      `INSERT INTO messagesgroup (group_id, sender_email, imageurl, message_type, time) 
       VALUES ($1, $2, $3, 'image', NOW())`,
      [groupId, sender_email,Image]
    );

    res.status(201).json({ success: true, message: "Images uploaded successfully" });
  } catch (error) {
    console.error("Database error:", error);
    res.status(500).json({ error: 'Failed to save image message to database' });
  }
});

app.post('/deletemessages', async (req, res) => {
  const { messagesId } = req.body;

  try {
   const result = await pool.query('DELETE FROM messagesgroup WHERE messagesg_id = $1', [messagesId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Message not found' });
    }
    return res.status(200).json({ message: 'Message deleted successfully' });
  } catch (error) {
    console.error('Error deleting message:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/historyimage', async (req, res) => {
  const { groupId } = req.body;

  try {
    const result = await pool.query(
      'SELECT imageurl,time FROM messagesgroup WHERE group_id = $1 AND message_type = $2', 
      [groupId, 'image']
    );

    if (result.rows.length > 0) {
      return res.status(200).json({ images: result.rows });
    } else {
      return res.status(404).json({ message: 'No images found for this group.' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'server error' });
  }

});

app.post('/getgroup', async (req, res) => {
  const { groupCode } = req.body;

  if (!groupCode) {
    return res.status(400).json({ success: false, message: 'group_code is required' });
  }

  try {
    const result = await pool.query('SELECT * FROM create_group WHERE group_code = $1', [groupCode]);
    
    console.log(result.rows);  // พิมพ์ผลลัพธ์เพื่อดูข้อมูลที่ได้รับ
    
    if (result.rows.length > 0) {
      return res.status(200).json({ success: true, userGroups: result.rows });
    } else {
      return res.status(200).json({ success: true, userGroups: [] });  // ส่งคืนอาเรย์ว่างถ้าไม่มีข้อมูล
    }
  } catch (err) {
    console.error('Error fetching user group', err.stack);
    return res.status(500).json({ success: false, message: 'Error fetching user group' });
  }
});

app.post('/updategroup', upload.array('images[]'), async (req, res) => {
  const {
    groupCode,
    group_name,
    type_group,
    latitude,
    longitude,
    placename,
    date,
    time,
    age,
    gender,
    max_participants,
    imagesToDelete,
    Province,
  } = req.body;
  const imagesToDeleteArray = typeof imagesToDelete === 'string' 
    ? JSON.parse(imagesToDelete) 
    : imagesToDelete;
  console.log('Received data:', req.body);
  console.log('Images to delete:', imagesToDeleteArray);
  console.log('Uploaded files:', req.files);

  try {
    const query = `
      UPDATE create_group
      SET group_name = $1,
          type_group = $2,
          latitude = $3,
          longitude = $4,
          placename = $5,
          date = $6,
          time = $7,
          age = $8,
          gender = $9,
          max_participants = $10,
          province = $12
      WHERE group_code = $11
    `;

    const values = [
      group_name,
      type_group,
      latitude,
      longitude,
      placename,
      date,
      time,
      age,
      gender,
      max_participants,
      groupCode,
      Province
    ];

    const result = await pool.query(query, values);

    if (imagesToDeleteArray && Array.isArray(imagesToDeleteArray) && imagesToDeleteArray.length > 0) {
      const deleteQuery = `
        UPDATE create_group
        SET image_path = ARRAY(SELECT unnest(image_path) EXCEPT SELECT unnest($1::text[]))
        WHERE group_code = $2
      `;
      await pool.query(deleteQuery, [imagesToDeleteArray, groupCode]);
    }

    if (req.files && req.files.length > 0) {
      const newImagePaths = req.files.map(file => file.filename);
      const updateImagesQuery = `
        UPDATE create_group
        SET image_path = image_path || $1::text[]
        WHERE group_code = $2
      `;
      await pool.query(updateImagesQuery, [newImagePaths, groupCode]);
    }

    if (result.rowCount > 0) {
      // ดึงสมาชิกทั้งหมดในกลุ่มที่ไม่ใช่เจ้าของกลุ่ม
      const membersQuery = `
        SELECT email_member
        FROM join_group
        WHERE group_code = $1 AND email_member != (
          SELECT email_owner
          FROM create_group
          WHERE group_code = $1
        )
      `;
      const membersResult = await pool.query(membersQuery, [groupCode]);

      if (membersResult.rows.length > 0) {
        for (const member of membersResult.rows) {
          await pool.query(
            `INSERT INTO notificationgroupstatus (email_member, message, created_at, group_code, group_name)
             VALUES ($1, $2, NOW(), $3, $4)`,
            [member.email_member, `The group ${group_name} has been updated. Please recheck`, groupCode, group_name]
          );
          console.log(`Notification sent to ${member.email_member} for group ${groupCode}`);
        }
      }

      return res.status(200).json({ success: true, message: 'Group updated successfully' });
    } else {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }
  } catch (err) {
    console.error('Error updating group data:', err.stack);
    return res.status(500).json({ success: false, message: 'Error updating group data' });
  }
});


app.post('/checkbanstatus', async (req, res) => {
  const { email } = req.body;
  try {
    const result = await pool.query('SELECT status FROM users WHERE email = $1', [email]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const userStatus = result.rows[0].status;

    // ส่งกลับสถานะผู้ใช้
    return res.json({ status: userStatus });
  } catch (error) {
    console.error('Error executing query: ', error);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/checktimeout', async (req, res) => {
  const { email } = req.body;
  try {
      const result = await pool.query('SELECT time_out FROM users WHERE email = $1', [email]);

      if (result.rows.length > 0) {
          const timeout = result.rows[0].time_out;
          const now = new Date();

          if (timeout && timeout > now) {
              res.status(200).json({ success: true, timeoutUntil: timeout.toISOString() }); 
          } else {
              res.status(200).json({ success: true, timeoutUntil: null });
          }
      } else {
          res.status(404).json({ success: false, message: 'User not found.' });
      }
  } catch (error) {
      console.error('Error checking timeout:', error);
      res.status(500).json({ success: false, message: 'Error checking timeout.' });
  }
});

async function checkGroups() {
  try {
    const result = await pool.query(`SELECT group_code, date, time FROM create_group WHERE group_status = '0'`);

    for (const group of result.rows) {
      const formattedDate = moment(`${group.date} ${group.time}`, 'DD/MM/YYYY hh:mm A').toDate();
      const now = new Date();
      const hoursPassed = (now - formattedDate) / (1000 * 60 * 60); 
      if (hoursPassed >= 24) {
        await pool.query(
          `UPDATE create_group SET group_status = '1' WHERE group_code = $1`,
          [group.group_code]
        );
        console.log(`Group ${group.group_code} has been ended automatically.`);

        await updateCredits(group.group_code);
      }
    }
  } catch (error) {
    console.error('Error checking groups:', error);
  }
}

// ฟังก์ชันเรียกใช้ API updatecredits
async function updateCredits(groupCode) {
  try {
    const response = await axios.post('http://192.168.1.106:3000/updatecredits', {groupCode});
    console.log(response.data.message);
  } catch (error) {
    console.error('Error calling updatecredits:', error);
  }
}

cron.schedule('0 * * * *', () => {
  console.log('Running scheduled task to check group statuses...');
  checkGroups();
});

app.post('/checkgroupstatus', async (req, res) => {
  const { groupCode } = req.body;
  try {
    const result = await pool.query(
      'SELECT group_status FROM create_group WHERE group_code = $1', 
      [groupCode]
    );

    if (result.rows.length > 0) {
      const groupStatus = result.rows[0].group_status;
      res.status(200).json({ success: true, groupStatus });
    } else {
      res.status(404).json({ success: false, message: 'Group not found' });
    }
  } catch (error) {
    console.error('Error checking group status:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.post('/submitrating', async (req, res) => {
  const { groupCode, rating } = req.body;

  try {
    const ownerResult = await pool.query(
      'SELECT email_owner FROM create_group WHERE group_code = $1',
      [groupCode]
    );

    if (ownerResult.rows.length > 0) {
      const emailOwner = ownerResult.rows[0].email_owner;

      await pool.query(
        `INSERT INTO credit_creator (email_owner, total_rating, rating_count, average_rating)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (email_owner) DO UPDATE SET 
           total_rating = credit_creator.total_rating + $2,
           rating_count = credit_creator.rating_count + 1,
           average_rating = (credit_creator.total_rating + $2) / (credit_creator.rating_count + 1)`,
        [emailOwner, rating, 1, rating] 
      );

      res.status(200).json({ success: true, message: 'Rating submitted and credit updated successfully' });
    } else {
      res.status(404).json({ success: false, message: 'Owner not found' });
    }
  } catch (error) {
    console.error('Error updating rating and credit:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.post('/getcreatorcredits', async (req, res) => {
  const { email } = req.body; 

  try {
    const result = await pool.query(
      'SELECT average_rating FROM credit_creator WHERE email_owner = $1',
      [email]
    );
    if (result.rows.length > 0) {
      const averageRating = result.rows[0].average_rating; 
      res.status(200).json({success: true, averageRating: averageRating,
      });
    } else {
      res.status(404).json({ success: false, message: 'Creator not found' });
    }
  } catch (error) {
    console.error('Error fetching creator credits:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

async function checkGroupstart() {
  try {
    const result = await pool.query(
      `SELECT cg.group_name, cg.email_owner, cg.time, cg.date, cg.group_code,
              array_agg(jg.email_member) AS email_members
       FROM create_group cg
       LEFT JOIN join_group jg ON cg.group_code = jg.group_code
       WHERE cg.group_status = '0'
       GROUP BY cg.group_name, cg.email_owner, cg.time, cg.date, cg.group_code`
    );

    for (const group of result.rows) {
      const formattedDate = moment(`${group.date} ${group.time}`, 'DD/MM/YYYY hh:mm A').toDate();
      const now = new Date();
      const hoursLeft = (formattedDate - now) / (1000 * 60 * 60);

      if (hoursLeft <= 24 && hoursLeft > 0) {
        // ตรวจสอบว่ามีการแจ้งเตือนสำหรับ group_code นี้แล้วหรือยังใน notificationgroupstatus
        const checkNotification = await pool.query(
          `SELECT 1 FROM notificationgroupstatus WHERE group_code = $1`,
          [group.group_code]
        );

        if (checkNotification.rowCount === 0) { // ถ้ายังไม่มีการแจ้งเตือนสำหรับ group_code นี้
          for (const emailMember of group.email_members) {
            await pool.query(
              `INSERT INTO notificationgroupstatus (group_code, message, created_at, group_name, email_member) VALUES ($1, $2, NOW(), $3, $4)`,
              [group.group_code, `Group ${group.group_name} has less than 24 hours remaining.`, group.group_name, emailMember]
            );
            console.log(`Notification for Group ${group.group_code} for member ${emailMember} has been added to the notifications table.`);
          }
        } else {
          console.log(`Notification for Group ${group.group_code} already exists.`);
        }
      }
    }
  } catch (error) {
    console.error('Error checking groups:', error);
  }
}

cron.schedule('0 * * * *', () => {
  console.log('Running checkGroups job...');
  checkGroupstart();
});

app.post('/gettimestart', async (req, res) => {
  const { groupCode } = req.body;
  
  try {
    const result = await pool.query(
      `SELECT time, date FROM create_group WHERE group_code = $1`, 
      [groupCode]
    );
    
    if (result.rows.length > 0) {
      res.status(200).json({ 
        time: result.rows[0].time, 
        date: result.rows[0].date 
      });
    } else {
      res.status(404).json({ message: 'Group not found' });
    }
  } catch (error) {
    console.error('Error fetching start time:', error);
    res.status(500).json({ message: 'Error fetching start time' });
  }
});

app.post('/sendmessagedirect', async (req, res) => {
  const { sender_email, receiver_email, message } = req.body;

  try {
      await pool.query(
          'INSERT INTO messagesdirect (sender_email, receiver_email, messages,time) VALUES ($1, $2, $3, NOW())',
          [sender_email, receiver_email, message]
      );
      return res.status(200).json({ success: true, message: 'Message sent' });
  } catch (err) {
      console.error('Error sending message', err);
      return res.status(500).json({ success: false, message: 'Failed to send message' });
  }
});

app.get('/getdirectmessages', async (req, res) => {
  const { receive_email, sender_email } = req.query;

  try {
    const result = await pool.query(
      `SELECT m.*, u.username, u.profile_image
       FROM messagesdirect m
       JOIN users u ON m.sender_email = u.email
       WHERE (m.sender_email = $1 AND m.receiver_email = $2) 
          OR (m.sender_email = $2 AND m.receiver_email = $1) 
       ORDER BY m.time ASC`,
      [receive_email, sender_email]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching messages:', error);
    return res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

app.post('/deletemessagesdirect', async (req, res) => {
  const { messagesId } = req.body;

  try {
   const result = await pool.query('DELETE FROM messagesdirect WHERE id_direct = $1', [messagesId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Message not found' });
    }
    return res.status(200).json({ message: 'Message deleted successfully' });
  } catch (error) {
    console.error('Error deleting message:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/getChatFriends', async (req, res) => {
  const { email } = req.query;
  try {
      const result = await pool.query(
          `SELECT DISTINCT ON (u.email)
              u.email,
              u.username,
              u.profile_image,
              m.messages AS last_message,
              m.time,
              m.sender_email AS last_sender,
              m.message_type,
              (SELECT username FROM users WHERE email = m.sender_email) AS last_sender_username
           FROM users u
           JOIN messagesdirect m ON (m.sender_email = u.email OR m.receiver_email = u.email)
           WHERE (m.sender_email = $1 OR m.receiver_email = $1)
             AND u.email != $1
           ORDER BY u.email, m.time DESC`, 
          [email]
      );
      return res.status(200).json(result.rows);
  } catch (err) {
      console.error('Error fetching friends', err);
      return res.status(500).json({ success: false, message: 'Failed to fetch friends' });
  }
});

app.post('/sendimagedirect', uploadChat.array('sendimagedirect'), async (req, res) => {
  const { receiver_email, sender_email } = req.body;

  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

 
  const imageUrls = req.files.map(file => file.filename); 
  const Image = `{${imageUrls.join(',')}}`;  

  try {
    await pool.query(
      `INSERT INTO messagesdirect (receiver_email, sender_email, imageurl, message_type, time) 
       VALUES ($1, $2, $3, 'image', NOW())`,
      [receiver_email, sender_email, Image]
    );

    res.status(201).json({ success: true, message: "Images sent successfully" });
  } catch (error) {
    console.error("Database error:", error);
    res.status(500).json({ error: 'Failed to save image message to database' });
  }
});

app.post('/historyimagedirect', async (req, res) => {
  const { sender_email, receiver_email } = req.body;

  try {
    const result = await pool.query(
      `SELECT imageurl, time 
       FROM messagesdirect 
       WHERE (sender_email = $1 AND receiver_email = $2) OR (sender_email = $2 AND receiver_email = $1) 
       AND message_type = $3 
       ORDER BY time ASC`, 
      [sender_email, receiver_email, 'image']
    );

    if (result.rows.length > 0) {
      return res.status(200).json({ images: result.rows });
    } else {
      return res.status(404).json({ message: 'No images found for this conversation.' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/getLatestDirectMessages', async (req, res) => {
  const { senderEmail, receiverEmail } = req.body; 

  try {
      const result = await pool.query(`
          SELECT dm.message, dm.time, u.username, u.email
          FROM messagesdirect dm
          JOIN users u ON dm.sender_email = u.email
          WHERE (dm.sender_email = $1 AND dm.receiver_email = $2) OR (dm.sender_email = $2 AND dm.receiver_email = $1)
          ORDER BY dm.time DESC
          LIMIT 1
      `, [senderEmail, receiverEmail]);

      if (result.rows.length === 0) {
          return res.status(404).json({ message: 'No direct messages found.' });
      }

      res.status(200).json(result.rows[0]); 
  } catch (error) {
      console.error("Error retrieving latest direct messages:", error);
      res.status(500).send('Error retrieving latest direct messages');
  }
});

app.post('/send-otp-reset', async (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000);
  const expiryTime = new Date(Date.now() + 2 * 60000); 

  try {
      await pool.query('UPDATE users SET otp = $1, otp_expire = $2 WHERE email = $3', [otp, expiryTime, email]);

      await sendEmail(email, otp);

      res.status(200).json({ success: true, message: 'OTP sent to your email.' });
  } catch (err) {
      console.error('Error sending OTP', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/verify-otp-reset', async (req, res) => {
  const { email, otp, newPassword } = req.body;

  try {
      const result = await pool.query('SELECT otp, otp_expire FROM users WHERE email = $1', [email]);
      const userData = result.rows[0];

      if (!userData || userData.otp !== otp) {
          return res.status(400).json({ success: false, message: 'Invalid OTP' });
      }

      const isExpired = moment().isAfter(moment(userData.otp_expire));
      if (isExpired) {
          return res.status(400).json({ success: false, message: 'OTP has expired.' });
      }

      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await pool.query('UPDATE users SET password = $1, otp = NULL, otp_expire = NULL WHERE email = $2', [hashedPassword, email]);

      res.json({ success: true, message: 'Password has been reset successfully.' });
  } catch (err) {
      console.error('Error verifying OTP', err.stack);
      res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

async function checkCredit() {
  try {
    const result = await pool.query(`SELECT * FROM users WHERE credits = '0'`);
    const userscredits = result.rows;


    if (userscredits.length > 0) {
      const emailList = userscredits.map(user => user.email);
      await pool.query(
        `UPDATE users SET status = '0' WHERE credits = '0'`
      );

      console.log(`Updated status to 0 for users with no credits: ${emailList.join(', ')}`);
    } else {
      console.log('No users found with credits equal to 0');
    }
  } catch (error) {
    console.error('Error checking credits:', error);
  }
}

cron.schedule('0 * * * *', () => {
  console.log('Running checkCredit job...');
  checkCredit();
});

app.post('/isoldpassword', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query('SELECT password FROM users WHERE email = $1', [email]);
    if (result.rows.length > 0) {
      const user = result.rows[0];
      const isMatch = await bcrypt.compare(password, user.password);
      if (isMatch) {
        return res.json({ isValid: true });
      } else {
        return res.json({ isValid: false });
      }
    } else {
      return res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Server error' });
  }
});
app.post('/updatepassword', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await pool.query('UPDATE users SET password = $1 WHERE email = $2', [hashedPassword, email]);

    return res.json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.post('/canclegroup', async (req, res) => {
  const { groupCode,reason,email } = req.body;

  try {
    if (!groupCode) {
      return res.status(400).json({ message: 'Group code is required.' });
    }

    const result = await pool.query(`UPDATE create_group SET group_status = '2' WHERE group_code = $1`, [groupCode]);
    await pool.query(
      `UPDATE users SET credits = CAST(credits AS INTEGER) - 1 WHERE email = $1`,
      [email]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Group not found or already updated.' });
    }

    await pool.query(`INSERT INTO reason (email, message, type, group_code) VALUES ($1, $2, 'canclegroup', $3)`, [email, reason, groupCode]);

    const members = await pool.query(`
      SELECT j.email_member, c.group_name, c.email_owner 
      FROM join_group j
      JOIN create_group c ON j.group_code = c.group_code
      WHERE j.group_code = $1
    `, [groupCode]);

    const ownerEmail = members.rows[0]?.email_owner; 
    const groupName = members.rows[0]?.group_name;

    for (const member of members.rows) {
      if (member.email_member !== ownerEmail) { 
        const message = `group "${groupName}" has been canceled because ${reason} `;
        
        await pool.query(`
          INSERT INTO notificationgroupstatus (email_member, message, group_name,group_code) VALUES ($1, $2,$3, $4)
        `, [member.email_member, message,groupName,groupCode]);
      }
    }

    res.status(200).json({ message: 'Group status updated and notifications sent to members.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error.' });
  }
});
  app.listen(port, () => {
    console.log(`Server runningon port ${port}`);
  });

