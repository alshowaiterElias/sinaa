import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { Request, Response, NextFunction } from 'express';

import sharp from 'sharp';

// Ensure uploads directory exists
const uploadDir = path.join(process.cwd(), 'uploads/products');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure storage (Memory storage for processing)
const storage = multer.memoryStorage();

// File filter
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG and WebP are allowed.'));
    }
};

// Export upload middleware
export const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Image processing middleware
export const processImage = async (req: Request, res: Response, next: NextFunction) => {
    if (!req.file) return next();

    try {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const filename = `image-${uniqueSuffix}.jpg`; // Always convert to JPEG
        const filepath = path.join(uploadDir, filename);
        const thumbFilename = `thumb_${filename}`;
        const thumbFilepath = path.join(uploadDir, thumbFilename);

        // Process main image
        await sharp(req.file.buffer)
            .resize(1024, 1024, { // Max dimensions
                fit: 'inside',
                withoutEnlargement: true
            })
            .toFormat('jpeg', { quality: 80 })
            .toFile(filepath);

        // Generate thumbnail
        await sharp(req.file.buffer)
            .resize(300, 300, {
                fit: 'cover',
            })
            .toFormat('jpeg', { quality: 80 })
            .toFile(thumbFilepath);

        // Update req.file to match diskStorage behavior
        req.file.filename = filename;
        req.file.path = filepath;
        req.file.destination = uploadDir;
        req.file.mimetype = 'image/jpeg'; // We converted to JPEG

        next();
    } catch (error) {
        next(error);
    }
};
