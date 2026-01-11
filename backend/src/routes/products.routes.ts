import { Router } from 'express';
import { authenticate, optionalAuth } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { body, query, param } from 'express-validator';
import {
    getAllProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct,
    getNearbyProducts,
    addProductImage,
    deleteProductImage,
    updateProductPoster,
    promoteImageAsPoster,
    getProductVariants,
    addProductVariant,
    updateProductVariant,
    deleteProductVariant,
    addProductTag,
    removeProductTag,
} from '../controllers/productController';
import { upload, processImage } from '../middleware/upload';

const router = Router();

// Validation rules
const productValidation = [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('nameAr').trim().notEmpty().withMessage('Arabic name is required'),
    body('basePrice').isFloat({ min: 0 }).withMessage('Price must be positive'),
    body('categoryId').isInt().withMessage('Category ID must be an integer'),
    // posterImageUrl is optional - can come from file upload
    body('posterImageUrl').optional().isURL().withMessage('Poster image must be a valid URL'),
];

// Public routes
router.get('/', optionalAuth, getAllProducts);
router.get('/nearby', getNearbyProducts);
router.get('/:id', getProductById);

// Protected routes (Project Owners)
router.post(
    '/',
    authenticate,
    upload.single('posterImage'),
    processImage,
    validate(productValidation),
    createProduct
);

router.put(
    '/:id',
    authenticate,
    validate([
        param('id').isInt(),
        ...productValidation.map(v => v.optional()),
    ]),
    updateProduct
);

router.delete(
    '/:id',
    authenticate,
    validate([param('id').isInt()]),
    deleteProduct
);

// Image Routes
router.post(
    '/:id/images',
    authenticate,
    upload.single('image'),
    processImage,
    addProductImage
);

router.delete(
    '/:id/images/:imageId',
    authenticate,
    deleteProductImage
);

// Poster Route
router.put(
    '/:id/poster',
    authenticate,
    upload.single('posterImage'),
    processImage,
    updateProductPoster
);

// Promote existing image as poster
router.put(
    '/:id/promote-image/:imageId',
    authenticate,
    promoteImageAsPoster
);

// Variant Routes
router.get('/:id/variants', getProductVariants);

router.post(
    '/:id/variants',
    authenticate,
    validate([
        body('name').trim().notEmpty(),
        body('nameAr').trim().notEmpty(),
        body('priceModifier').isFloat(),
    ]),
    addProductVariant
);

router.put(
    '/variants/:variantId',
    authenticate,
    validate([
        body('name').optional().trim().notEmpty(),
        body('nameAr').optional().trim().notEmpty(),
        body('priceModifier').optional().isFloat(),
    ]),
    updateProductVariant
);

router.delete(
    '/variants/:variantId',
    authenticate,
    deleteProductVariant
);

// Tag Routes
router.post(
    '/:id/tags',
    authenticate,
    validate([
        body('tagId').isInt().withMessage('Tag ID must be an integer'),
    ]),
    addProductTag
);

router.delete(
    '/:id/tags/:tagId',
    authenticate,
    removeProductTag
);

export default router;
