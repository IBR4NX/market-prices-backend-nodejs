-- QUERY TRUNCATED
-- =========================================================
-- IBOVS PRICE PLATFORM
-- PostgreSQL Database Schema
-- =========================================================

-- =========================================================
-- 1. EXTENSIONS
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- 2. ENUM TYPES
-- =========================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'user_role'
    ) THEN
        CREATE TYPE user_role AS ENUM (
            'USER',
            'EMPLOYEE',
            'ADMIN'
        );

END IF;

IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE
        typname = 'submission_status'
) THEN CREATE TYPE submission_status AS ENUM(
    'PENDING',
    'APPROVED',
    'REJECTED'
);

END IF;

END $$;

-- =========================================================
-- 3. USERS
-- =========================================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'USER',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 4. CATEGORIES
-- =========================================================

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 5. PRODUCTS
-- =========================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    category_id UUID NOT NULL,
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    quantity DECIMAL(12, 3) NOT NULL DEFAULT 1,
    unit VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_products_quantity CHECK (quantity > 0),
    CONSTRAINT uq_products_definition UNIQUE (
        category_id,
        name,
        quantity,
        unit
    )
);

-- =========================================================
-- 6. CITIES
-- =========================================================

CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 7. PRICE SUBMISSIONS
-- =========================================================

CREATE TABLE IF NOT EXISTS price_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    product_id UUID NOT NULL,
    city_id UUID NOT NULL,
    user_id UUID NOT NULL,
    price DECIMAL(14, 2) NOT NULL,
    note TEXT,
    status submission_status NOT NULL DEFAULT 'PENDING',
    rejection_reason TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID,
    CONSTRAINT fk_submissions_product FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_submissions_city FOREIGN KEY (city_id) REFERENCES cities (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_submissions_user FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_submissions_reviewer FOREIGN KEY (reviewed_by) REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_submissions_price CHECK (price > 0),
    CONSTRAINT chk_rejection_reason CHECK (
        status <> 'REJECTED'
        OR rejection_reason IS NOT NULL
    ),
    CONSTRAINT chk_review_data CHECK (
        (
            status = 'PENDING'
            AND reviewed_at IS NULL
            AND reviewed_by IS NULL
        )
        OR (
            status IN ('APPROVED', 'REJECTED')
            AND reviewed_at IS NOT NULL
            AND reviewed_by IS NOT NULL
        )
    )
);

-- =========================================================
-- 8. CURRENT PRICES
-- =========================================================

CREATE TABLE IF NOT EXISTS current_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    slug VARCHAR(255) NOT NULL UNIQUE,
    product_id UUID NOT NULL,
    city_id UUID NOT NULL,
    price DECIMAL(14, 2) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    CONSTRAINT fk_current_prices_product FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_current_prices_city FOREIGN KEY (city_id) REFERENCES cities (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_current_prices_updater FOREIGN KEY (updated_by) REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_current_price CHECK (price > 0),
    CONSTRAINT uq_current_product_city UNIQUE (product_id, city_id)
);

-- =========================================================
-- 9. PRICE HISTORY
-- =========================================================

CREATE TABLE IF NOT EXISTS price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    product_id UUID NOT NULL,
    city_id UUID NOT NULL,
    price DECIMAL(14, 2) NOT NULL,
    source_submission_id UUID,
    approved_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_product FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_history_city FOREIGN KEY (city_id) REFERENCES cities (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_history_submission FOREIGN KEY (source_submission_id) REFERENCES price_submissions (id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_history_approver FOREIGN KEY (approved_by) REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_history_price CHECK (price > 0)
);

-- =========================================================
-- 10. INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id);

CREATE INDEX IF NOT EXISTS idx_products_name ON products (name);

CREATE INDEX IF NOT EXISTS idx_products_active ON products (is_active);

CREATE INDEX IF NOT EXISTS idx_submissions_status ON price_submissions (status);

CREATE INDEX IF NOT EXISTS idx_submissions_product ON price_submissions (product_id);

CREATE INDEX IF NOT EXISTS idx_submissions_city ON price_submissions (city_id);

CREATE INDEX IF NOT EXISTS idx_submissions_user ON price_submissions (user_id);

CREATE INDEX IF NOT EXISTS idx_submissions_reviewed_by ON price_submissions (reviewed_by);

CREATE INDEX IF NOT EXISTS idx_submissions_created ON price_submissions (submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_current_prices_product ON current_prices (product_id);

CREATE INDEX IF NOT EXISTS idx_current_prices_city ON current_prices (city_id);

CREATE INDEX IF NOT EXISTS idx_history_product ON price_history (product_id);

CREATE INDEX IF NOT EXISTS idx_history_city ON price_history (city_id);

CREATE INDEX IF NOT EXISTS idx_history_date ON price_history (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_history_product_city_date ON price_history (
    product_id,
    city_id,
    created_at DESC
);

-- =========================================================
-- 11. UPDATED_AT FUNCTION
-- =========================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- =========================================================
-- 12. UPDATED_AT TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_categories_updated_at ON categories;

CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_cities_updated_at ON cities;

CREATE TRIGGER trg_cities_updated_at
BEFORE UPDATE ON cities
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- =========================================================
-- 13. APPROVE PRICE FUNCTION
-- =========================================================
--
-- عند اعتماد PriceSubmission:
--
-- 1. يتم تحديث CurrentPrice
-- 2. يتم إضافة السعر إلى PriceHistory
--
-- =========================================================

CREATE OR REPLACE FUNCTION approve_price_submission(
    p_submission_id UUID,
    p_employee_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id UUID;
    v_city_id UUID;
    v_price DECIMAL(14,2);
    v_status submission_status;
BEGIN

    -- Get submission
    SELECT
        product_id,
        city_id,
        price,
        status
    INTO
        v_product_id,
        v_city_id,
        v_price,
        v_status
    FROM price_submissions
    WHERE id = p_submission_id
    FOR UPDATE;


    -- Submission does not exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Price submission not found';
    END IF;


    -- Only pending submissions can be approved
    IF v_status <> 'PENDING' THEN
        RAISE EXCEPTION 'Only pending submissions can be approved';
    END IF;


    -- Mark submission as approved
    UPDATE price_submissions
    SET
        status = 'APPROVED',
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = p_employee_id
    WHERE id = p_submission_id;


    -- Save old/current price to history
    INSERT INTO price_history (
        product_id,
        city_id,
        price,
        source_submission_id,
        approved_by
    )
    SELECT
        product_id,
        city_id,
        price,
        NULL,
        p_employee_id
    FROM current_prices
    WHERE product_id = v_product_id
      AND city_id = v_city_id;


    -- Update current price
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

END;
$$;

-- =========================================================
-- 14. REJECT PRICE FUNCTION
-- =========================================================

CREATE OR REPLACE FUNCTION reject_price_submission(
    p_submission_id UUID,
    p_employee_id UUID,
    p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_status submission_status;
BEGIN

    SELECT status
    INTO v_status
    FROM price_submissions
    WHERE id = p_submission_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION 'Price submission not found';
    END IF;


    IF v_status <> 'PENDING' THEN
        RAISE EXCEPTION 'Only pending submissions can be rejected';
    END IF;


    IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
        RAISE EXCEPTION 'Rejection reason is required';
    END IF;


    UPDATE price_submissions
    SET
        status = 'REJECTED',
        rejection_reason = TRIM(p_reason),
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = p_employee_id
    WHERE id = p_submission_id;

END;
$$;