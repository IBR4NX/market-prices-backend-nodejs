import { Router, Request, Response } from "express";
import pool from "../../database";
import {
  InternalErrorResponse,
  NotFoundResponse,
  SuccessResponse,
} from "../../core/ApiResponse";
const router = Router();

router.get("/", async (req: Request, res: Response) => {
  var message;
  try {
    const { search, slug } = req.query;
    const result = await pool.query(
      ` SELECT
    p.*,
    c AS category,
    COALESCE(
        (
            SELECT jsonb_agg(
                to_jsonb(cp) || jsonb_build_object(
                    'city', to_jsonb(ci)
                )
            )
            FROM current_prices cp
            JOIN cities ci ON ci.id = cp.city_id
            WHERE cp.product_id = p.id
        ),
        '[]'::jsonb
    ) AS current_prices,
    COALESCE(
        (
            SELECT jsonb_agg(
                to_jsonb(ph) || jsonb_build_object(
                    'city', to_jsonb(ci),
                    'approved_by_user', to_jsonb(u)
                )
                ORDER BY ph.created_at DESC
            )
            FROM price_history ph
            JOIN cities ci ON ci.id = ph.city_id
            JOIN users u ON u.id = ph.approved_by
            WHERE ph.product_id = p.id
        ),
        '[]'::jsonb
    ) AS price_history
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.slug = $1
  AND p.is_active = TRUE;`,
      [search || slug],
    );
    if (result.rows.length > 0) {
      return new SuccessResponse("successful", result.rows).send(res);
    }

    return new NotFoundResponse("No data found").send(res);
  } catch (error) {
    console.error(error);
    message = "Failed to get information";
    return new InternalErrorResponse(message).send(res);
  }
});

export default router;
