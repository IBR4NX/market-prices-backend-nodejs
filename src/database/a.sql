                        SELECT
                            p.*,
                            (
                                SELECT
                                    jsonb_agg (to_jsonb (c))
                                FROM
                                    categories c
                                WHERE
                                    c.id = p.category_id
                            ) as category,
                            COALESCE(
                                (
                                    SELECT
                                        jsonb_agg (
                                            to_jsonb (cp) || jsonb_build_object ('city', to_jsonb (ci))
                                        )
                                    FROM
                                        current_prices cp
                                        JOIN cities ci ON ci.id = cp.city_id
                                    WHERE
                                        cp.product_id = p.id
                                ),
                                '[]'
                            ) AS current_prices,
                            COALESCE(
                                (
                                    SELECT
                                        jsonb_agg (
                                            to_jsonb (ph) || jsonb_build_object (
                                                'city',
                                                to_jsonb (ci),
                                                'approved_by_user',
                                                to_jsonb (u)
                                            )
                                            ORDER BY
                                                ph.created_at DESC
                                        )
                                    FROM
                                        price_history ph
                                        JOIN cities ci ON ci.id = ph.city_id
                                        JOIN users u ON u.id = ph.approved_by
                                    WHERE
                                        ph.product_id = p.id
                                ),
                                '[]'
                            ) AS price_history
                        FROM
                            products p
                            JOIN categories c ON c.id = p.category_id
                            WHERE p.slug = '$1' OR p.name LIKE '%' || TRIM($1) || '%'
                            AND p.is_active = TRUE;