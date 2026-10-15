-- =========================================================
-- IBOVS PRICE PLATFORM
-- DATABASE FUNCTIONS
-- PostgreSQL
-- =========================================================

-- =========================================================
-- 1. USERS
-- =========================================================

-- ---------------------------------------------------------
-- Create User
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION create_user(
    p_name VARCHAR(100),
    p_email VARCHAR(255),
    p_password VARCHAR(255),
    p_role user_role DEFAULT 'USER'
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    email VARCHAR(255),
    role user_role,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    INSERT INTO users (
        name,
        email,
        password,
        role
    )
    VALUES (
        TRIM(p_name),
        LOWER(TRIM(p_email)),
        p_password,
        p_role
    )
    RETURNING
        users.id,
        users.name,
        users.email,
        users.role,
        users.is_active,
        users.created_at;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Email already exists';
END;
$$;

-- ---------------------------------------------------------
-- Get User By Email
-- Password is intentionally NOT returned
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_user_by_email(
    p_email VARCHAR(255)
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    email VARCHAR(255),
    password VARCHAR(255),
    role user_role,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        u.id,
        u.name,
        u.email,
        u.password,
        u.role,
        u.is_active,
        u.created_at
    FROM users u
    WHERE u.email = LOWER(TRIM(p_email))
    LIMIT 1;
$$;

-- ---------------------------------------------------------
-- Get User By ID
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_user_by_id(
    p_user_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    email VARCHAR(255),
    role user_role,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        u.id,
        u.name,
        u.email,
        u.role,
        u.is_active,
        u.created_at
    FROM users u
    WHERE u.id = p_user_id;
$$;

-- ---------------------------------------------------------
-- Update User
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION update_user(
    p_user_id UUID,
    p_name VARCHAR(100) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_role user_role DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    email VARCHAR(255),
    role user_role,
    is_active BOOLEAN,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    UPDATE users
    SET
        name = COALESCE(NULLIF(TRIM(p_name), ''), name),
        email = COALESCE(LOWER(NULLIF(TRIM(p_email), '')), email),
        role = COALESCE(p_role, role),
        is_active = COALESCE(p_is_active, is_active)
    WHERE users.id = p_user_id
    RETURNING
        users.id,
        users.name,
        users.email,
        users.role,
        users.is_active,
        users.updated_at;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Email already exists';
END;
$$;

-- =========================================================
-- 2. CATEGORIES
-- =========================================================

-- ---------------------------------------------------------
-- Create Category
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION create_category(
    p_name VARCHAR(100),
    p_description TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    description TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    INSERT INTO categories (
        name,
        description
    )
    VALUES (
        TRIM(p_name),
        p_description
    )
    RETURNING
        categories.id,
        categories.name,
        categories.description,
        categories.is_active,
        categories.created_at;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Category already exists';
END;
$$;

-- ---------------------------------------------------------
-- Get Categories
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_categories(
    p_include_inactive BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    slug varchar(255),
    description TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id,
        c.name,
        c.slug,
        c.description,
        c.is_active,
        c.created_at
    FROM categories c
    WHERE
        p_include_inactive
        OR c.is_active = TRUE
    ORDER BY c.name;
$$;

-- ---------------------------------------------------------
-- Get Category By ID
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_category_by_id(
    p_category_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    slug varchar(255),
    description TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id,
        c.name,
        c.description,
        c.is_active,
        c.created_at
    FROM categories c
    WHERE c.id = p_category_id;
$$;

-- ---------------------------------------------------------
-- Update Category
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION update_category(
    p_category_id UUID,
    p_name VARCHAR(100) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    description TEXT,
    is_active BOOLEAN,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    UPDATE categories
    SET
        name = COALESCE(NULLIF(TRIM(p_name), ''), name),
        description = COALESCE(p_description, description),
        is_active = COALESCE(p_is_active, is_active)
    WHERE categories.id = p_category_id
    RETURNING
        categories.id,
        categories.name,
        categories.description,
        categories.is_active,
        categories.updated_at;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Category already exists';
END;
$$;

-- =========================================================
-- 3. CITIES
-- =========================================================

-- ---------------------------------------------------------
-- Create City
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION create_city(
    p_name VARCHAR(100)
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    INSERT INTO cities (name)
    VALUES (TRIM(p_name))
    RETURNING
        cities.id,
        cities.name,
        cities.is_active,
        cities.created_at;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'City already exists';
END;
$$;

-- ---------------------------------------------------------
-- Get Cities
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_cities(
    p_include_inactive BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    slug varchar(255),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id,
        c.name,
        c.slug,
        c.is_active,
        c.created_at
    FROM cities c
    WHERE
        p_include_inactive
        OR c.is_active = TRUE
    ORDER BY c.name;
$$;

-- ---------------------------------------------------------
-- Get City By ID
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_city_by_id(
    p_city_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id,
        c.name,
        c.is_active,
        c.created_at
    FROM cities c
    WHERE c.id = p_city_id;
$$;

-- ---------------------------------------------------------
-- Update City
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION update_city(
    p_city_id UUID,
    p_name VARCHAR(100) DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    is_active BOOLEAN,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    UPDATE cities
    SET
        name = COALESCE(NULLIF(TRIM(p_name), ''), name),
        is_active = COALESCE(p_is_active, is_active)
    WHERE cities.id = p_city_id
    RETURNING
        cities.id,
        cities.name,
        cities.is_active,
        cities.updated_at;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'City not found';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'City already exists';
END;
$$;

-- =========================================================
-- 4. PRODUCTS
-- =========================================================

-- ---------------------------------------------------------
-- Create Product
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION create_product(
    p_category_name VARCHAR(150),
    p_name VARCHAR(150),
    p_description TEXT,
    p_quantity DECIMAL(12,3),
    p_unit VARCHAR(50)
)
RETURNS TABLE (
    id UUID,
    category_id UUID,
    name VARCHAR(150),
    description TEXT,
    quantity DECIMAL(12,3),
    unit VARCHAR(50),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id UUID;
BEGIN
    SELECT c.id
    INTO v_category_id
    FROM categories c
    WHERE TRIM(c.name) = TRIM(p_category_name)
      AND c.is_active = TRUE
    LIMIT 1;

    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Category not found or inactive';
    END IF;

    RETURN QUERY
    INSERT INTO products (
        category_id,
        name,
        description,
        quantity,
        unit
    )
    VALUES (
        v_category_id,
        TRIM(p_name),
        p_description,
        p_quantity,
        TRIM(p_unit)
    )
    RETURNING
        products.id,
        products.category_id,
        products.name,
        products.description,
        products.quantity,
        products.unit,
        products.is_active,
        products.created_at;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Product already exists';
END;
$$;

-- ---------------------------------------------------------
-- Get Products
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_products(
    p_category_id UUID DEFAULT NULL,
    p_city_id UUID DEFAULT NULL,
    p_search TEXT DEFAULT NULL,
    p_include_inactive BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id UUID,
    category_id UUID,
    category_name VARCHAR(100),
    name VARCHAR(150),
    description TEXT,
    quantity DECIMAL(12,3),
    unit VARCHAR(50),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id,
        p.category_id,
        c.name AS category_name,
        p.name,
        p.description,
        p.quantity,
        p.unit,
        p.is_active,
        p.created_at
    FROM products p
    INNER JOIN categories c
        ON c.id = p.category_id
    WHERE
        (
            p_category_id IS NULL
            OR p.category_id = p_category_id
        )
        AND
        (
            p_city_id IS NULL
            OR EXISTS (
                SELECT 1
                FROM current_prices cp
                WHERE cp.product_id = p.id
                  AND cp.city_id = p_city_id
            )
        )
        AND
        (
            p_search IS NULL
            OR p.name ILIKE '%' || TRIM(p_search) || '%'
        )
        AND
        (
            p_include_inactive
            OR p.is_active = TRUE
        )
    ORDER BY p.name;
$$;

-- ---------------------------------------------------------
-- Get Product By ID
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_product_by_id(
    p_product_id UUID
)
RETURNS TABLE (
    id UUID,
    category_id UUID,
    category_name VARCHAR(100),
    name VARCHAR(150),
    description TEXT,
    quantity DECIMAL(12,3),
    unit VARCHAR(50),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id,
        p.category_id,
        c.name AS category_name,
        p.name,
        p.description,
        p.quantity,
        p.unit,
        p.is_active,
        p.created_at
    FROM products p
    INNER JOIN categories c
        ON c.id = p.category_id
    WHERE p.id = p_product_id;
$$;

-- ---------------------------------------------------------
-- Update Product
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION update_product(
    p_product_id UUID,
    p_category_name VARCHAR(150) DEFAULT NULL,
    p_name VARCHAR(150) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_quantity DECIMAL(12,3) DEFAULT NULL,
    p_unit VARCHAR(50) DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    category_id UUID,
    name VARCHAR(150),
    description TEXT,
    quantity DECIMAL(12,3),
    unit VARCHAR(50),
    is_active BOOLEAN,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id UUID;
BEGIN
    IF p_category_name IS NOT NULL THEN
        SELECT c.id
        INTO v_category_id
        FROM categories c
        WHERE LOWER(TRIM(c.name)) = LOWER(TRIM(p_category_name))
          AND c.is_active IS TRUE
        LIMIT 1;

        IF v_category_id IS NULL THEN
            RAISE EXCEPTION
                'Category not found or inactive: "%"',
                p_category_name;
        END IF;
    END IF;

    RETURN QUERY
    UPDATE products as pr
    SET
        category_id = COALESCE(v_category_id, pr.category_id),
        name = COALESCE(NULLIF(TRIM(p_name), ''), pr.name),
        description = COALESCE(p_description, pr.description),
        quantity = COALESCE(p_quantity, pr.quantity),
        unit = COALESCE(NULLIF(TRIM(p_unit), ''), pr.unit),
        is_active = COALESCE(p_is_active, pr.is_active)
    WHERE pr.id = p_product_id
    RETURNING
        pr.id,
        pr.category_id,
        pr.name,
        pr.description,
        pr.quantity,
        pr.unit,
        pr.is_active,
        pr.updated_at;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product not found';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Product definition already exists';
END;
$$;

-- =========================================================
-- 5. PRICE SUBMISSIONS
-- =========================================================

-- ---------------------------------------------------------
-- Submit New Price
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION create_price_submission(
    p_product_id UUID,
    p_city_id UUID,
    p_user_id UUID,
    p_price DECIMAL(14,2),
    p_note TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    city_id UUID,
    user_id UUID,
    price DECIMAL(14,2),
    note TEXT,
    status submission_status,
    submitted_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM products
        WHERE products.id = p_product_id
          AND products.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Product not found or inactive';
    END IF;


    IF NOT EXISTS (
        SELECT 1
        FROM cities
        WHERE cities.id = p_city_id
          AND cities.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'City not found or inactive';
    END IF;


    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = p_user_id
          AND users.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User not found or inactive';
    END IF;


    IF p_price <= 0 THEN
        RAISE EXCEPTION 'Price must be greater than zero';
    END IF;


    RETURN QUERY
    INSERT INTO price_submissions (
        product_id,
        city_id,
        user_id,
        price,
        note
    )
    VALUES (
        p_product_id,
        p_city_id,
        p_user_id,
        p_price,
        p_note
    )
    RETURNING
        price_submissions.id,
        price_submissions.product_id,
        price_submissions.city_id,
        price_submissions.user_id,
        price_submissions.price,
        price_submissions.note,
        price_submissions.status,
        price_submissions.submitted_at;
END;
$$;

-- ---------------------------------------------------------
-- Get Pending Submissions
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pending_submissions()
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_name VARCHAR(150),
    city_id UUID,
    city_name VARCHAR(100),
    user_id UUID,
    user_name VARCHAR(100),
    price DECIMAL(14,2),
    note TEXT,
    submitted_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ps.id,
        ps.product_id,
        p.name AS product_name,
        ps.city_id,
        c.name AS city_name,
        ps.user_id,
        u.name AS user_name,
        ps.price,
        ps.note,
        ps.submitted_at
    FROM price_submissions ps
    INNER JOIN products p
        ON p.id = ps.product_id
    INNER JOIN cities c
        ON c.id = ps.city_id
    INNER JOIN users u
        ON u.id = ps.user_id
    WHERE ps.status = 'PENDING'
    ORDER BY ps.submitted_at ASC;
$$;

-- ---------------------------------------------------------
-- Get User Submissions
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_user_submissions(
    p_user_id UUID,
    p_status submission_status DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_name VARCHAR(150),
    city_id UUID,
    city_name VARCHAR(100),
    price DECIMAL(14,2),
    note TEXT,
    status submission_status,
    rejection_reason TEXT,
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ps.id,
        ps.product_id,
        p.name AS product_name,
        ps.city_id,
        c.name AS city_name,
        ps.price,
        ps.note,
        ps.status,
        ps.rejection_reason,
        ps.submitted_at,
        ps.reviewed_at
    FROM price_submissions ps
    INNER JOIN products p
        ON p.id = ps.product_id
    INNER JOIN cities c
        ON c.id = ps.city_id
    WHERE
        ps.user_id = p_user_id
        AND (
            p_status IS NULL
            OR ps.status = p_status
        )
    ORDER BY ps.submitted_at DESC;
$$;

-- =========================================================
-- 6. APPROVE PRICE
-- =========================================================
--drop FUNCTION approve_price_submission
CREATE OR REPLACE FUNCTION approve_price_submission(
    p_submission_id UUID,
    p_employee_id UUID
)
  RETURNS TABLE (
    out_submission_id UUID,
    out_product_id UUID,
    out_city_id UUID,
    out_new_price DECIMAL(14,2),
    out_previous_price DECIMAL(14,2),
    out_approved_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE

    v_product_id UUID;
    v_city_id UUID;
    v_price DECIMAL(14,2);
    v_status submission_status;
    v_previous_price DECIMAL(14,2);
    v_approved_at TIMESTAMPTZ;

BEGIN

    -- Verify employee/admin
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE id = p_employee_id
          AND role IN ('EMPLOYEE', 'ADMIN')
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User is not authorized to approve prices';
    END IF;


-- Lock submission
SELECT
    ps.product_id,
    ps.city_id,
    ps.price,
    ps.status
INTO
    v_product_id,
    v_city_id,
    v_price,
    v_status
FROM price_submissions AS ps
WHERE ps.id = p_submission_id
FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION 'Price submission not found';
    END IF;


    IF v_status <> 'PENDING' THEN
        RAISE EXCEPTION 'Only pending submissions can be approved';
    END IF;


-- Get current price
SELECT cp.price
INTO v_previous_price
FROM current_prices AS cp
WHERE cp.product_id = v_product_id
  AND cp.city_id = v_city_id;


    -- Approve submission
    UPDATE price_submissions
    SET
        status = 'APPROVED',
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = p_employee_id
    WHERE id = p_submission_id
    RETURNING reviewed_at
    INTO v_approved_at;


    -- Save previous price in history
    IF v_previous_price IS NOT NULL THEN

        INSERT INTO price_history (
            product_id,
            city_id,
            price,
            source_submission_id,
            approved_by
        )
        VALUES (
            v_product_id,
            v_city_id,
            v_previous_price,
            p_submission_id,
            p_employee_id
        );

    END IF;


    -- Update or create current price
    INSERT INTO current_prices (
        product_id,
        city_id,
        price,
        updated_at,
        updated_by
    )
    VALUES (
        v_product_id,
        v_city_id,
        v_price,
        CURRENT_TIMESTAMP,
        p_employee_id
    )
    ON CONFLICT (product_id, city_id)
    DO UPDATE SET
        price = EXCLUDED.price,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = EXCLUDED.updated_by;


    RETURN QUERY
    SELECT
        p_submission_id,
        v_product_id,
        v_city_id,
        v_price,
        v_previous_price,
        v_approved_at;

END;
$$;

-- =========================================================
-- 7. REJECT PRICE
-- =========================================================

CREATE OR REPLACE FUNCTION reject_price_submission(
    p_submission_id UUID,
    p_employee_id UUID,
    p_reason TEXT
)
RETURNS TABLE (
    id UUID,
    status submission_status,
    rejection_reason TEXT,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status submission_status;
BEGIN

    -- Verify employee/admin
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = p_employee_id
          AND users.role IN ('EMPLOYEE', 'ADMIN')
          AND users.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User is not authorized to reject prices';
    END IF;


    -- Get current status
    SELECT status
    INTO v_status
    FROM price_submissions
    WHERE price_submissions.id = p_submission_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION 'Price submission not found';
    END IF;


    IF v_status <> 'PENDING' THEN
        RAISE EXCEPTION 'Only pending submissions can be rejected';
    END IF;


    IF p_reason IS NULL
       OR LENGTH(TRIM(p_reason)) = 0
    THEN
        RAISE EXCEPTION 'Rejection reason is required';
    END IF;


    RETURN QUERY
    UPDATE price_submissions
    SET
        status = 'REJECTED',
        rejection_reason = TRIM(p_reason),
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = p_employee_id
    WHERE price_submissions.id = p_submission_id
    RETURNING
        price_submissions.id,
        price_submissions.status,
        price_submissions.rejection_reason,
        price_submissions.reviewed_at,
        price_submissions.reviewed_by;

END;
$$;

-- =========================================================
-- 8. CURRENT PRICES
-- =========================================================

-- ---------------------------------------------------------
-- Get Current Price
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_current_price(
    p_product_id UUID,
    p_city_id UUID
)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_name VARCHAR(150),
    city_id UUID,
    city_name VARCHAR(100),
    price DECIMAL(14,2),
    quantity DECIMAL(12,3),
    unit VARCHAR(50),
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        cp.id,
        cp.product_id,
        p.name AS product_name,
        cp.city_id,
        c.name AS city_name,
        cp.price,
        p.quantity,
        p.unit,
        cp.updated_at
    FROM current_prices cp
    INNER JOIN products p
        ON p.id = cp.product_id
    INNER JOIN cities c
        ON c.id = cp.city_id
    WHERE
        cp.product_id = p_product_id
        AND cp.city_id = p_city_id;
$$;

-- ---------------------------------------------------------
-- Get Current Prices
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_current_prices(
    p_city_name     TEXT DEFAULT NULL,
    p_category_name TEXT DEFAULT NULL,
    p_search        TEXT DEFAULT NULL
)
RETURNS TABLE (
    product_id    UUID,
    product_name  VARCHAR(150),
    category_id   UUID,
    category_name VARCHAR(100),
    city_id       UUID,
    city_name     VARCHAR(100),
    price         DECIMAL(14,2),
    quantity      DECIMAL(12,3),
    unit          VARCHAR(50),
    updated_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        cp.product_id,
        p.name        AS product_name,
        p.category_id,
        cat.name      AS category_name,
        cp.city_id,
        c.name        AS city_name,
        cp.price,
        p.quantity,
        p.unit,
        cp.updated_at
    FROM current_prices cp
    INNER JOIN products p
        ON p.id = cp.product_id
    INNER JOIN categories cat
        ON cat.id = p.category_id
    INNER JOIN cities c
        ON c.id = cp.city_id
    WHERE
        p.is_active = TRUE
        AND cat.is_active = TRUE
        AND c.is_active = TRUE
        AND (
            p_city_name IS NULL
            OR TRIM(p_city_name) = ''
            OR c.name ILIKE '%' || TRIM(p_city_name) || '%'
        )
        AND (
            p_category_name IS NULL
            OR TRIM(p_category_name) = ''
            OR cat.name ILIKE '%' || TRIM(p_category_name) || '%'
        )
        AND (
            p_search IS NULL
            OR TRIM(p_search) = ''
            OR p.name   ILIKE '%' || TRIM(p_search) || '%'
            OR c.name   ILIKE '%' || TRIM(p_search) || '%'
            OR cat.name ILIKE '%' || TRIM(p_search) || '%'
        )
    ORDER BY p.name, c.name;
$$;

-- =========================================================
-- 9. PRICE HISTORY
-- =========================================================

-- ---------------------------------------------------------
-- Get Price History
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_price_history(
    p_product_name VARCHAR(150),
    p_city_name VARCHAR(100),
    p_from TIMESTAMPTZ DEFAULT NULL,
    p_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_name VARCHAR(150),
    city_id UUID,
    city_name VARCHAR(100),
    price DECIMAL(14,2),
    approved_by UUID,
    approver_name VARCHAR(100),
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ph.id,
        ph.product_id,
        p.name AS product_name,
        ph.city_id,
        c.name AS city_name,
        ph.price,
        ph.approved_by,
        u.name AS approver_name,
        ph.created_at
    FROM price_history AS ph
    INNER JOIN products AS p
        ON p.id = ph.product_id
    INNER JOIN cities AS c
        ON c.id = ph.city_id
    INNER JOIN users AS u
        ON u.id = ph.approved_by
    WHERE LOWER(TRIM(p.name)) = LOWER(TRIM(p_product_name))
      AND LOWER(TRIM(c.name)) = LOWER(TRIM(p_city_name))
      AND (
          p_from IS NULL
          OR ph.created_at >= p_from
      )
      AND (
          p_to IS NULL
          OR ph.created_at <= p_to
      )
    ORDER BY ph.created_at ASC;
$$;

-- =========================================================
-- 10. PRICE STATISTICS
-- =========================================================

-- ---------------------------------------------------------
-- Get Price Statistics
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_price_statistics(
    p_product_id UUID,
    p_city_id UUID
)
RETURNS TABLE (
    current_price DECIMAL(14,2),
    previous_price DECIMAL(14,2),
    price_change DECIMAL(14,2),
    price_change_percentage DECIMAL(10,2),
    lowest_price DECIMAL(14,2),
    highest_price DECIMAL(14,2)
)
LANGUAGE sql
STABLE
AS $$
    WITH history AS (
        SELECT
            price,
            created_at
        FROM price_history
        WHERE product_id = p_product_id
          AND city_id = p_city_id
    ),
    current_data AS (
        SELECT price
        FROM current_prices
        WHERE product_id = p_product_id
          AND city_id = p_city_id
    ),
    previous_data AS (
        SELECT price
        FROM history
        ORDER BY created_at DESC
        LIMIT 1
    )
    SELECT
        (SELECT price FROM current_data),

        (SELECT price FROM previous_data),

        (
            (SELECT price FROM current_data)
            -
            (SELECT price FROM previous_data)
        ),

        CASE
            WHEN (SELECT price FROM previous_data) IS NULL
                 OR (SELECT price FROM previous_data) = 0
            THEN NULL
            ELSE ROUND(
                (
                    (
                        (SELECT price FROM current_data)
                        -
                        (SELECT price FROM previous_data)
                    )
                    /
                    (SELECT price FROM previous_data)
                ) * 100,
                2
            )
        END,

        LEAST(
            (SELECT MIN(price) FROM history),
            (SELECT price FROM current_data)
        ),

        GREATEST(
            (SELECT MAX(price) FROM history),
            (SELECT price FROM current_data)
        );
$$;

-- =========================================================
-- 11. DASHBOARD STATISTICS
-- =========================================================

CREATE OR REPLACE FUNCTION get_dashboard_statistics()
RETURNS TABLE (
    total_users BIGINT,
    total_products BIGINT,
    total_categories BIGINT,
    total_cities BIGINT,
    pending_submissions BIGINT,
    approved_submissions BIGINT,
    rejected_submissions BIGINT,
    current_prices_count BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        (SELECT COUNT(*) FROM users),
        (SELECT COUNT(*) FROM products WHERE is_active = TRUE),
        (SELECT COUNT(*) FROM categories WHERE is_active = TRUE),
        (SELECT COUNT(*) FROM cities WHERE is_active = TRUE),
        (
            SELECT COUNT(*)
            FROM price_submissions
            WHERE status = 'PENDING'
        ),
        (
            SELECT COUNT(*)
            FROM price_submissions
            WHERE status = 'APPROVED'
        ),
        (
            SELECT COUNT(*)
            FROM price_submissions
            WHERE status = 'REJECTED'
        ),
        (SELECT COUNT(*) FROM current_prices);
$$;

-- =========================================================
-- 12. DELETE / DEACTIVATE
-- =========================================================

-- ---------------------------------------------------------
-- Deactivate Product
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION deactivate_product(
    p_product_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE products
    SET is_active = FALSE
    WHERE id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product not found';
    END IF;

    RETURN TRUE;

END;
$$;

-- ---------------------------------------------------------
-- Deactivate Category
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION deactivate_category(
    p_category_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE categories
    SET is_active = FALSE
    WHERE id = p_category_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found';
    END IF;

    RETURN TRUE;

END;
$$;

-- ---------------------------------------------------------
-- Deactivate City
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION deactivate_city(
    p_city_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE cities
    SET is_active = FALSE
    WHERE id = p_city_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'City not found';
    END IF;

    RETURN TRUE;

END;
$$;

SELECT * FROM get_current_price (null, null)

-- =========================================================
-- END
-- =========================================================



