const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const { v4: uuidv4 } = require('uuid');

// Configure multer for memory storage (we'll process with sharp)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG and PNG images are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB default
  },
});

// Middleware to process and save images
const processImage = async (req, res, next) => {
  if (!req.file) {
    return next();
  }

  try {
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    const imagesDir = path.join(uploadDir, 'images');
    const thumbnailsDir = path.join(uploadDir, 'thumbnails');

    // Ensure directories exist
    await fs.mkdir(imagesDir, { recursive: true });
    await fs.mkdir(thumbnailsDir, { recursive: true });

    const filename = `${uuidv4()}.jpg`;
    const imagePath = path.join(imagesDir, filename);
    const thumbnailPath = path.join(thumbnailsDir, filename);

    // Process and save full image (max 1920x1920, 85% quality)
    await sharp(req.file.buffer)
      .resize(1920, 1920, {
        fit: 'inside',
        withoutEnlargement: true,
      })
      .jpeg({ quality: 85 })
      .toFile(imagePath);

    // Create thumbnail (200x150)
    await sharp(req.file.buffer)
      .resize(200, 150, {
        fit: 'cover',
      })
      .jpeg({ quality: 80 })
      .toFile(thumbnailPath);

    // Add file info to request
    req.processedImage = {
      filename: filename,
      path: imagePath,
      thumbnailPath: thumbnailPath,
      url: `/uploads/images/${filename}`,
      thumbnailUrl: `/uploads/thumbnails/${filename}`,
    };

    next();
  } catch (error) {
    console.error('Image processing error:', error);
    next(new Error('Failed to process image'));
  }
};

module.exports = {
  upload,
  processImage,
};
