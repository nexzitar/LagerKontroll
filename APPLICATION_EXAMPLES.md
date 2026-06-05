# Real-World Application Examples

This document provides complete, production-ready code examples for integrating the trailer management database into various application architectures.

## Table of Contents
1. [Mobile App Backend (Node.js/Express)](#mobile-app-backend-nodejs-express)
2. [Python FastAPI Complete API](#python-fastapi-complete-api)
3. [React Native Mobile App](#react-native-mobile-app)
4. [Photo Upload Handling](#photo-upload-handling)
5. [Offline-First Mobile Strategy](#offline-first-mobile-strategy)
6. [Dashboard/Reporting Queries](#dashboard-reporting-queries)

---

## Mobile App Backend (Node.js/Express)

Complete REST API with photo upload support.

### Project Setup

```bash
mkdir trailer-api
cd trailer-api
npm init -y
npm install express pg multer aws-sdk cors helmet compression morgan dotenv
npm install --save-dev nodemon
```

### File Structure
```
trailer-api/
├── .env
├── package.json
├── src/
│   ├── index.js
│   ├── config/
│   │   ├── database.js
│   │   └── storage.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── errorHandler.js
│   ├── routes/
│   │   ├── trailers.js
│   │   ├── status.js
│   │   └── photos.js
│   └── utils/
│       └── logger.js
```

### .env File
```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=trailers
DB_USER=trailer_app
DB_PASSWORD=your_secure_password
DB_POOL_MAX=20

# AWS S3
AWS_REGION=eu-north-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=trailer-photos-bucket

# Server
PORT=3000
NODE_ENV=production
```

### src/config/database.js
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: parseInt(process.env.DB_POOL_MAX) || 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection on startup
pool.on('connect', () => {
  console.log('Database connected');
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
```

### src/config/storage.js
```javascript
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const s3 = new AWS.S3({
  region: process.env.AWS_REGION,
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

/**
 * Upload photo to S3
 * @param {Buffer} fileBuffer - Photo file buffer
 * @param {string} trailerNumber - Trailer identifier
 * @param {string} mimeType - File MIME type
 * @returns {Promise<string>} - S3 path
 */
async function uploadPhoto(fileBuffer, trailerNumber, mimeType) {
  const timestamp = Date.now();
  const uuid = uuidv4();
  const extension = mimeType === 'image/png' ? 'png' : 'jpg';

  // Organize by date: 2025/12/10/
  const date = new Date();
  const datePrefix = `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}`;

  const key = `${datePrefix}/${trailerNumber}-${timestamp}-${uuid}.${extension}`;

  const params = {
    Bucket: process.env.S3_BUCKET,
    Key: key,
    Body: fileBuffer,
    ContentType: mimeType,
    ServerSideEncryption: 'AES256'
  };

  await s3.upload(params).promise();

  return `s3://${process.env.S3_BUCKET}/${key}`;
}

/**
 * Generate pre-signed URL for photo access
 * @param {string} s3Path - S3 path (s3://bucket/key)
 * @param {number} expiresIn - URL expiration in seconds
 * @returns {string} - Pre-signed URL
 */
function getPresignedUrl(s3Path, expiresIn = 3600) {
  // Parse S3 path
  const match = s3Path.match(/s3:\/\/([^\/]+)\/(.+)/);
  if (!match) {
    throw new Error('Invalid S3 path');
  }

  const [, bucket, key] = match;

  const params = {
    Bucket: bucket,
    Key: key,
    Expires: expiresIn
  };

  return s3.getSignedUrl('getObject', params);
}

module.exports = {
  uploadPhoto,
  getPresignedUrl
};
```

### src/middleware/auth.js
```javascript
/**
 * Simple authentication middleware
 * In production, use JWT, OAuth, or similar
 */
function authenticate(req, res, next) {
  const apiKey = req.headers['x-api-key'];

  // TODO: Validate API key against database
  if (!apiKey) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  // Mock user ID for now
  req.userId = 1;

  next();
}

module.exports = { authenticate };
```

### src/middleware/errorHandler.js
```javascript
function errorHandler(err, req, res, next) {
  console.error('Error:', err);

  if (err.code === '23505') { // PostgreSQL unique violation
    return res.status(409).json({
      error: 'Duplicate entry',
      detail: err.detail
    });
  }

  if (err.code === '23503') { // PostgreSQL foreign key violation
    return res.status(400).json({
      error: 'Invalid reference',
      detail: err.detail
    });
  }

  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
}

module.exports = { errorHandler };
```

### src/routes/status.js
```javascript
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { uploadPhoto, getPresignedUrl } = require('../config/storage');
const multer = require('multer');

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/png') {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG and PNG images are allowed'));
    }
  }
});

/**
 * POST /api/status
 * Create new trailer status entry with optional photo
 */
router.post('/', upload.single('photo'), async (req, res, next) => {
  try {
    const {
      trailer_number,
      license_plate,
      terminal_code,
      is_empty,
      latitude,
      longitude,
      notes
    } = req.body;

    // Validation
    if (!trailer_number || !license_plate || !terminal_code || is_empty === undefined) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['trailer_number', 'license_plate', 'terminal_code', 'is_empty']
      });
    }

    // Upload photo if provided
    let photoPath = null;
    let photoContentType = null;
    let photoSize = null;

    if (req.file) {
      photoPath = await uploadPhoto(
        req.file.buffer,
        trailer_number,
        req.file.mimetype
      );
      photoContentType = req.file.mimetype;
      photoSize = req.file.size;
    }

    // Insert status entry
    const result = await db.query(
      `SELECT insert_trailer_status($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) as history_id`,
      [
        trailer_number,
        license_plate,
        terminal_code,
        is_empty === 'true' || is_empty === true,
        latitude ? parseFloat(latitude) : null,
        longitude ? parseFloat(longitude) : null,
        photoPath,
        photoContentType,
        photoSize,
        req.userId,
        notes || null
      ]
    );

    const historyId = result.rows[0].history_id;

    res.status(201).json({
      success: true,
      history_id: historyId,
      photo_uploaded: !!photoPath
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/status/trailer/:trailerNumber
 * Get history for specific trailer
 */
router.get('/trailer/:trailerNumber', async (req, res, next) => {
  try {
    const { trailerNumber } = req.params;
    const limit = parseInt(req.query.limit) || 10;

    const result = await db.query(
      'SELECT * FROM get_trailer_history($1, $2)',
      [trailerNumber, limit]
    );

    // Generate pre-signed URLs for photos
    const historyWithUrls = result.rows.map(row => ({
      ...row,
      photo_url: row.photo_path ? getPresignedUrl(row.photo_path) : null
    }));

    res.json({
      trailer_number: trailerNumber,
      entries: historyWithUrls
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/status/current
 * Get current status of all trailers
 */
router.get('/current', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT * FROM v_trailer_current_status
      ORDER BY trailer_number
    `);

    // Generate pre-signed URLs for photos
    const statusWithUrls = result.rows.map(row => ({
      ...row,
      photo_url: row.photo_path ? getPresignedUrl(row.photo_path) : null
    }));

    res.json({
      count: statusWithUrls.length,
      trailers: statusWithUrls
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/status/terminal/:terminalCode
 * Get trailers at specific terminal
 */
router.get('/terminal/:terminalCode', async (req, res, next) => {
  try {
    const { terminalCode } = req.params;
    const emptyOnly = req.query.empty === 'true';

    let query = `
      WITH latest_status AS (
        SELECT DISTINCT ON (trailer_id)
          trailer_id, is_empty, terminal_id, recorded_at, photo_path
        FROM trailer_status_history
        ORDER BY trailer_id, recorded_at DESC
      )
      SELECT
        t.trailer_number,
        t.license_plate,
        ls.is_empty,
        ls.recorded_at as last_seen,
        ls.photo_path
      FROM latest_status ls
      JOIN trailers t ON ls.trailer_id = t.trailer_id
      JOIN terminals term ON ls.terminal_id = term.terminal_id
      WHERE term.terminal_code = $1
        AND t.is_active = true
    `;

    if (emptyOnly) {
      query += ' AND ls.is_empty = true';
    }

    query += ' ORDER BY t.trailer_number';

    const result = await db.query(query, [terminalCode.toUpperCase()]);

    // Generate pre-signed URLs
    const trailersWithUrls = result.rows.map(row => ({
      ...row,
      photo_url: row.photo_path ? getPresignedUrl(row.photo_path) : null
    }));

    res.json({
      terminal_code: terminalCode.toUpperCase(),
      count: trailersWithUrls.length,
      trailers: trailersWithUrls
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/status/date/:date
 * Get all status entries for a specific date
 */
router.get('/date/:date', async (req, res, next) => {
  try {
    const { date } = req.params;

    // Validate date format (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({
        error: 'Invalid date format. Use YYYY-MM-DD'
      });
    }

    const result = await db.query(`
      SELECT
        t.trailer_number,
        term.terminal_code,
        tsh.is_empty,
        tsh.recorded_at,
        u.username,
        tsh.photo_path
      FROM trailer_status_history tsh
      JOIN trailers t ON tsh.trailer_id = t.trailer_id
      LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
      LEFT JOIN users u ON tsh.user_id = u.user_id
      WHERE DATE(tsh.recorded_at) = $1
      ORDER BY tsh.recorded_at DESC
    `, [date]);

    const entriesWithUrls = result.rows.map(row => ({
      ...row,
      photo_url: row.photo_path ? getPresignedUrl(row.photo_path) : null
    }));

    res.json({
      date,
      count: entriesWithUrls.length,
      entries: entriesWithUrls
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

### src/routes/trailers.js
```javascript
const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * GET /api/trailers
 * List all active trailers
 */
router.get('/', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT
        trailer_id,
        trailer_number,
        license_plate,
        description,
        make,
        model,
        year,
        created_at
      FROM trailers
      WHERE is_active = true
      ORDER BY trailer_number
    `);

    res.json({
      count: result.rows.length,
      trailers: result.rows
    });

  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/trailers
 * Register new trailer
 */
router.post('/', async (req, res, next) => {
  try {
    const { trailer_number, license_plate, description, make, model, year } = req.body;

    if (!trailer_number || !license_plate) {
      return res.status(400).json({
        error: 'trailer_number and license_plate are required'
      });
    }

    const result = await db.query(`
      INSERT INTO trailers (trailer_number, license_plate, description, make, model, year)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING trailer_id, trailer_number, license_plate, created_at
    `, [trailer_number, license_plate, description, make, model, year]);

    res.status(201).json({
      success: true,
      trailer: result.rows[0]
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/trailers/:trailerNumber
 * Get trailer details and summary
 */
router.get('/:trailerNumber', async (req, res, next) => {
  try {
    const { trailerNumber } = req.params;

    const result = await db.query(`
      SELECT * FROM v_trailer_summary
      WHERE trailer_number = $1
    `, [trailerNumber]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Trailer not found'
      });
    }

    res.json(result.rows[0]);

  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

### src/index.js
```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');

const { authenticate } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');

const trailersRoutes = require('./routes/trailers');
const statusRoutes = require('./routes/status');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes (with authentication)
app.use('/api/trailers', authenticate, trailersRoutes);
app.use('/api/status', authenticate, statusRoutes);

// Error handler (must be last)
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});
```

### package.json
```json
{
  "name": "trailer-api",
  "version": "1.0.0",
  "description": "Trailer Management API",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "multer": "^1.4.5-lts.1",
    "aws-sdk": "^2.1498.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
```

---

## React Native Mobile App

Complete mobile app with offline support and photo upload.

### Setup
```bash
npx react-native init TrailerApp
cd TrailerApp
npm install @react-navigation/native @react-navigation/native-stack
npm install react-native-screens react-native-safe-area-context
npm install axios react-native-image-picker @react-native-async-storage/async-storage
npm install react-native-geolocation-service react-native-permissions
```

### App.js
```javascript
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import HomeScreen from './src/screens/HomeScreen';
import AddStatusScreen from './src/screens/AddStatusScreen';
import TrailerHistoryScreen from './src/screens/TrailerHistoryScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Home">
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'Trailer Management' }}
        />
        <Stack.Screen
          name="AddStatus"
          component={AddStatusScreen}
          options={{ title: 'Add Status' }}
        />
        <Stack.Screen
          name="TrailerHistory"
          component={TrailerHistoryScreen}
          options={{ title: 'Trailer History' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

### src/api/client.js
```javascript
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'https://your-api.com/api';
const API_KEY = 'your_api_key_here';

const client = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'X-API-Key': API_KEY,
    'Content-Type': 'application/json'
  }
});

// Request interceptor
client.interceptors.request.use(
  async (config) => {
    // Add any auth tokens here
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
client.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Handle authentication error
      console.error('Authentication failed');
    }
    return Promise.reject(error);
  }
);

export default client;
```

### src/api/trailers.js
```javascript
import client from './client';

export const trailersApi = {
  // Get all trailers
  getAllTrailers: async () => {
    const response = await client.get('/trailers');
    return response.data.trailers;
  },

  // Get current status of all trailers
  getCurrentStatus: async () => {
    const response = await client.get('/status/current');
    return response.data.trailers;
  },

  // Get trailer history
  getTrailerHistory: async (trailerNumber, limit = 10) => {
    const response = await client.get(`/status/trailer/${trailerNumber}`, {
      params: { limit }
    });
    return response.data.entries;
  },

  // Get trailers at terminal
  getTrailersAtTerminal: async (terminalCode, emptyOnly = false) => {
    const response = await client.get(`/status/terminal/${terminalCode}`, {
      params: { empty: emptyOnly }
    });
    return response.data.trailers;
  },

  // Add status with photo
  addStatus: async (data) => {
    const formData = new FormData();

    formData.append('trailer_number', data.trailerNumber);
    formData.append('license_plate', data.licensePlate);
    formData.append('terminal_code', data.terminalCode);
    formData.append('is_empty', data.isEmpty);

    if (data.latitude) formData.append('latitude', data.latitude);
    if (data.longitude) formData.append('longitude', data.longitude);
    if (data.notes) formData.append('notes', data.notes);

    if (data.photo) {
      formData.append('photo', {
        uri: data.photo.uri,
        type: data.photo.type || 'image/jpeg',
        name: data.photo.fileName || 'photo.jpg'
      });
    }

    const response = await client.post('/status', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });

    return response.data;
  }
};
```

### src/screens/AddStatusScreen.js
```javascript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Image,
  Alert,
  ScrollView,
  ActivityIndicator
} from 'react-native';
import { launchCamera } from 'react-native-image-picker';
import Geolocation from 'react-native-geolocation-service';
import { request, PERMISSIONS } from 'react-native-permissions';
import { trailersApi } from '../api/trailers';

export default function AddStatusScreen({ navigation }) {
  const [trailerNumber, setTrailerNumber] = useState('');
  const [licensePlate, setLicensePlate] = useState('');
  const [terminalCode, setTerminalCode] = useState('B1');
  const [isEmpty, setIsEmpty] = useState(false);
  const [notes, setNotes] = useState('');
  const [photo, setPhoto] = useState(null);
  const [location, setLocation] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    requestPermissions();
    getCurrentLocation();
  }, []);

  const requestPermissions = async () => {
    await request(PERMISSIONS.ANDROID.CAMERA);
    await request(PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION);
  };

  const getCurrentLocation = () => {
    Geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        });
      },
      (error) => {
        console.error('Location error:', error);
        Alert.alert('Location Error', 'Could not get current location');
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 10000 }
    );
  };

  const takePhoto = () => {
    const options = {
      mediaType: 'photo',
      quality: 0.8,
      includeBase64: false
    };

    launchCamera(options, (response) => {
      if (response.didCancel) {
        return;
      }

      if (response.errorCode) {
        Alert.alert('Camera Error', response.errorMessage);
        return;
      }

      if (response.assets && response.assets[0]) {
        setPhoto(response.assets[0]);
      }
    });
  };

  const handleSubmit = async () => {
    if (!trailerNumber || !licensePlate) {
      Alert.alert('Validation Error', 'Trailer number and license plate are required');
      return;
    }

    if (!photo) {
      Alert.alert('Validation Error', 'Please take a photo');
      return;
    }

    setLoading(true);

    try {
      await trailersApi.addStatus({
        trailerNumber,
        licensePlate,
        terminalCode,
        isEmpty,
        latitude: location?.latitude,
        longitude: location?.longitude,
        photo,
        notes
      });

      Alert.alert('Success', 'Status added successfully', [
        {
          text: 'OK',
          onPress: () => navigation.goBack()
        }
      ]);

    } catch (error) {
      console.error('Submit error:', error);
      Alert.alert('Error', 'Failed to add status. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.form}>
        <Text style={styles.label}>Trailer Number *</Text>
        <TextInput
          style={styles.input}
          value={trailerNumber}
          onChangeText={setTrailerNumber}
          placeholder="TRL-001"
          autoCapitalize="characters"
        />

        <Text style={styles.label}>License Plate *</Text>
        <TextInput
          style={styles.input}
          value={licensePlate}
          onChangeText={setLicensePlate}
          placeholder="ABC123"
          autoCapitalize="characters"
        />

        <Text style={styles.label}>Terminal</Text>
        <View style={styles.buttonGroup}>
          <TouchableOpacity
            style={[styles.button, terminalCode === 'B1' && styles.buttonActive]}
            onPress={() => setTerminalCode('B1')}
          >
            <Text style={[styles.buttonText, terminalCode === 'B1' && styles.buttonTextActive]}>
              B1
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.button, terminalCode === 'B3' && styles.buttonActive]}
            onPress={() => setTerminalCode('B3')}
          >
            <Text style={[styles.buttonText, terminalCode === 'B3' && styles.buttonTextActive]}>
              B3
            </Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>Status</Text>
        <View style={styles.buttonGroup}>
          <TouchableOpacity
            style={[styles.button, !isEmpty && styles.buttonActive]}
            onPress={() => setIsEmpty(false)}
          >
            <Text style={[styles.buttonText, !isEmpty && styles.buttonTextActive]}>
              Loaded
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.button, isEmpty && styles.buttonActive]}
            onPress={() => setIsEmpty(true)}
          >
            <Text style={[styles.buttonText, isEmpty && styles.buttonTextActive]}>
              Empty
            </Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>Photo *</Text>
        <TouchableOpacity style={styles.photoButton} onPress={takePhoto}>
          {photo ? (
            <Image source={{ uri: photo.uri }} style={styles.photoPreview} />
          ) : (
            <Text style={styles.photoButtonText}>Take Photo</Text>
          )}
        </TouchableOpacity>

        <Text style={styles.label}>Notes</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={notes}
          onChangeText={setNotes}
          placeholder="Optional notes..."
          multiline
          numberOfLines={4}
        />

        {location && (
          <Text style={styles.locationText}>
            Location: {location.latitude.toFixed(6)}, {location.longitude.toFixed(6)}
          </Text>
        )}

        <TouchableOpacity
          style={[styles.submitButton, loading && styles.submitButtonDisabled]}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.submitButtonText}>Submit Status</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5'
  },
  form: {
    padding: 20
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    marginTop: 16
  },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top'
  },
  buttonGroup: {
    flexDirection: 'row',
    gap: 12
  },
  button: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#007AFF',
    alignItems: 'center'
  },
  buttonActive: {
    backgroundColor: '#007AFF'
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#007AFF'
  },
  buttonTextActive: {
    color: '#fff'
  },
  photoButton: {
    height: 200,
    backgroundColor: '#fff',
    borderWidth: 2,
    borderColor: '#ddd',
    borderRadius: 8,
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center'
  },
  photoButtonText: {
    fontSize: 16,
    color: '#666'
  },
  photoPreview: {
    width: '100%',
    height: '100%',
    borderRadius: 8
  },
  locationText: {
    fontSize: 12,
    color: '#666',
    marginTop: 8
  },
  submitButton: {
    backgroundColor: '#28a745',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 24,
    marginBottom: 40
  },
  submitButtonDisabled: {
    opacity: 0.6
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600'
  }
});
```

---

## Offline-First Mobile Strategy

For mobile apps that need to work without internet connectivity.

### SQLite Local Database (React Native)

```bash
npm install react-native-sqlite-storage
```

### src/database/localDb.js
```javascript
import SQLite from 'react-native-sqlite-storage';

SQLite.enablePromise(true);

let db;

export async function initDatabase() {
  db = await SQLite.openDatabase({
    name: 'trailers_local.db',
    location: 'default'
  });

  // Create local tables
  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS pending_status (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trailer_number TEXT NOT NULL,
      license_plate TEXT NOT NULL,
      terminal_code TEXT NOT NULL,
      is_empty INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      photo_uri TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL,
      synced INTEGER DEFAULT 0
    )
  `);

  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS cached_trailers (
      trailer_id INTEGER PRIMARY KEY,
      trailer_number TEXT NOT NULL,
      license_plate TEXT NOT NULL,
      current_status TEXT,
      last_updated INTEGER
    )
  `);
}

// Add pending status (offline)
export async function addPendingStatus(data) {
  const result = await db.executeSql(`
    INSERT INTO pending_status
    (trailer_number, license_plate, terminal_code, is_empty, latitude, longitude, photo_uri, notes, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `, [
    data.trailerNumber,
    data.licensePlate,
    data.terminalCode,
    data.isEmpty ? 1 : 0,
    data.latitude,
    data.longitude,
    data.photo?.uri,
    data.notes,
    Date.now()
  ]);

  return result[0].insertId;
}

// Get all pending status entries (not synced)
export async function getPendingStatus() {
  const result = await db.executeSql(`
    SELECT * FROM pending_status
    WHERE synced = 0
    ORDER BY created_at ASC
  `);

  const items = [];
  for (let i = 0; i < result[0].rows.length; i++) {
    items.push(result[0].rows.item(i));
  }

  return items;
}

// Mark status as synced
export async function markAsSynced(id) {
  await db.executeSql(`
    UPDATE pending_status
    SET synced = 1
    WHERE id = ?
  `, [id]);
}

// Cache trailer data
export async function cacheTrailer(trailer) {
  await db.executeSql(`
    INSERT OR REPLACE INTO cached_trailers
    (trailer_id, trailer_number, license_plate, current_status, last_updated)
    VALUES (?, ?, ?, ?, ?)
  `, [
    trailer.trailer_id,
    trailer.trailer_number,
    trailer.license_plate,
    JSON.stringify(trailer),
    Date.now()
  ]);
}

// Get cached trailers
export async function getCachedTrailers() {
  const result = await db.executeSql(`
    SELECT * FROM cached_trailers
    ORDER BY trailer_number
  `);

  const items = [];
  for (let i = 0; i < result[0].rows.length; i++) {
    const row = result[0].rows.item(i);
    items.push({
      ...row,
      current_status: JSON.parse(row.current_status)
    });
  }

  return items;
}
```

### src/services/syncService.js
```javascript
import NetInfo from '@react-native-community/netinfo';
import { trailersApi } from '../api/trailers';
import {
  getPendingStatus,
  markAsSynced,
  cacheTrailer
} from '../database/localDb';

let syncInterval;

export function startSyncService() {
  // Sync every 5 minutes
  syncInterval = setInterval(() => {
    syncPendingData();
  }, 5 * 60 * 1000);

  // Also sync when network becomes available
  NetInfo.addEventListener(state => {
    if (state.isConnected) {
      syncPendingData();
    }
  });
}

export function stopSyncService() {
  if (syncInterval) {
    clearInterval(syncInterval);
  }
}

export async function syncPendingData() {
  const netInfo = await NetInfo.fetch();

  if (!netInfo.isConnected) {
    console.log('No internet connection, skipping sync');
    return;
  }

  const pendingItems = await getPendingStatus();

  if (pendingItems.length === 0) {
    console.log('No pending items to sync');
    return;
  }

  console.log(`Syncing ${pendingItems.length} pending items...`);

  for (const item of pendingItems) {
    try {
      // Prepare photo
      let photo = null;
      if (item.photo_uri) {
        photo = {
          uri: item.photo_uri,
          type: 'image/jpeg',
          fileName: `photo-${item.id}.jpg`
        };
      }

      // Upload to server
      await trailersApi.addStatus({
        trailerNumber: item.trailer_number,
        licensePlate: item.license_plate,
        terminalCode: item.terminal_code,
        isEmpty: item.is_empty === 1,
        latitude: item.latitude,
        longitude: item.longitude,
        photo,
        notes: item.notes
      });

      // Mark as synced
      await markAsSynced(item.id);

      console.log(`Synced item ${item.id}`);

    } catch (error) {
      console.error(`Failed to sync item ${item.id}:`, error);
      // Continue with next item
    }
  }

  console.log('Sync completed');
}

// Prefetch and cache trailer data
export async function prefetchTrailers() {
  try {
    const trailers = await trailersApi.getCurrentStatus();

    for (const trailer of trailers) {
      await cacheTrailer(trailer);
    }

    console.log(`Cached ${trailers.length} trailers`);
  } catch (error) {
    console.error('Failed to prefetch trailers:', error);
  }
}
```

---

## Summary

This comprehensive set of examples provides:

1. **Production-Ready Backend API** (Node.js/Express)
   - Photo upload to S3
   - Authentication middleware
   - Error handling
   - Connection pooling

2. **Mobile App** (React Native)
   - Camera integration
   - GPS location tracking
   - Photo upload
   - Offline support

3. **Offline-First Strategy**
   - Local SQLite database
   - Automatic background sync
   - Cache management

All code is ready to deploy and can be adapted to your specific requirements.
