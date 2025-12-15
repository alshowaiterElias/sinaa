import { Request, Response } from 'express';
import { Tag } from '../models';
import { sendSuccess, sendError, sendValidationError } from '../utils/helpers';

export const getAllTags = async (req: Request, res: Response) => {
    try {
        const tags = await Tag.findAll({
            order: [['name', 'ASC']],
        });
        return sendSuccess(res, tags);
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error fetching tags', 500, error);
    }
};

export const createTag = async (req: Request, res: Response) => {
    try {
        const { name, nameAr } = req.body;

        if (!name) {
            return sendValidationError(res, [{ field: 'name', message: 'Tag name is required' }]);
        }

        // Check if tag already exists
        const existingTag = await Tag.findOne({ where: { name } });
        if (existingTag) {
            return sendSuccess(res, existingTag, 'Tag already exists');
        }

        const tag = await Tag.create({
            name,
            nameAr: nameAr || name, // Use English name if Arabic not provided
        });

        return sendSuccess(res, tag, 'Tag created successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error creating tag', 500, error);
    }
};

export const findOrCreateTag = async (req: Request, res: Response) => {
    try {
        const { name, nameAr } = req.body;

        if (!name) {
            return sendValidationError(res, [{ field: 'name', message: 'Tag name is required' }]);
        }

        // Find or create the tag
        const [tag] = await Tag.findOrCreate({
            where: { name },
            defaults: { name, nameAr: nameAr || name },
        });

        return sendSuccess(res, tag);
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error finding/creating tag', 500, error);
    }
};
