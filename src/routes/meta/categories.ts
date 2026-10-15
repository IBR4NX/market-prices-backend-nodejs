import { Request, Response, Router } from "express";

import pool from "../../database";
import { InternalErrorResponse, NotFoundResponse, SuccessResponse } from "../../core/ApiResponse";
import { cache } from "../../core/cache";

const router = Router();

router.get("/", async (req: Request, res: Response) => {
  try {
    const includeInactive = req.query.includeInactive === "true";
    const cacheKey = `categories:list:${includeInactive}`;
    const cachedData = await cache.get(cacheKey);
    if (cachedData) {
      return new SuccessResponse("successful", cachedData).send(res);
    }
    const result = await pool.query("select * from get_categories($1::boolean);", [includeInactive]);

    if (result.rows.length > 0) {
      await cache.set(cacheKey, result.rows, 60);
      return new SuccessResponse("successful", result.rows).send(res);
    }

    return new NotFoundResponse("No data found").send(res);
  } catch {
    return new InternalErrorResponse("Failed to get categories").send(res);
  }
});

router.post("/", async (req: Request, res: Response) => {
  try {
    const { name, description } = req.body;
    const result = await pool.query("select * from create_category($1::varchar, $2::text);", [
      name,
      description ?? null,
    ]);

    if (result.rows.length > 0) {
      return new SuccessResponse("successful", result.rows).send(res);
    }

    return new NotFoundResponse("No data found").send(res);
  } catch {
    return new InternalErrorResponse("Failed to create category").send(res);
  }
});

router.patch("/:id", async (req: Request, res: Response) => {
  try {
    const { name, description, is_active } = req.body;
    console.log(req.params.id, req.query, req.body);

    const result = await pool.query("select * from update_category($1::uuid, $2::varchar, $3::text, $4::boolean)", [
      req.params.id,
      name ?? null,
      description ?? null,
      is_active ?? null,
    ]);

    if (result.rows.length > 0) {
      return new SuccessResponse("successful", result.rows).send(res);
    }

    return new NotFoundResponse("No data found").send(res);
  } catch (error) {
    console.error(error);
    return new InternalErrorResponse("Failed to update category").send(res);
  }
});

export default router;
