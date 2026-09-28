-- ==============================================================================
-- VIBE-FASHION 쇼핑몰 데이터베이스 스키마 (Supabase SQL Editor 실행용)
-- ==============================================================================

-- 1. UUID 및 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 공통 함수: updated_at 자동 갱신 트리거 함수
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ==============================================================================
-- [테이블 1] profiles (회원 프로필 - auth.users 연동)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT,
    avatar_url TEXT,
    phone TEXT,
    grade TEXT NOT NULL DEFAULT 'BRONZE' CHECK (grade IN ('BRONZE', 'SILVER', 'GOLD', 'VIP')),
    total_spent INTEGER NOT NULL DEFAULT 0 CHECK (total_spent >= 0),
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 2] categories (카테고리)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    parent_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 3] products (상품)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price INTEGER NOT NULL CHECK (price >= 0),
    sale_price INTEGER CHECK (sale_price IS NULL OR (sale_price >= 0 AND sale_price <= price)),
    badge TEXT, -- 'BEST', 'NEW', 'SALE' 등
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SOLDOUT', 'HIDDEN')),
    view_count INTEGER NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 4] product_options (상품 옵션 - 색상, 사이즈, 재고)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.product_options (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    color TEXT,
    size TEXT,
    additional_price INTEGER NOT NULL DEFAULT 0,
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 5] product_images (상품 이미지)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.product_images (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 6] carts (장바구니)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.carts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    option_id BIGINT REFERENCES public.product_options(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_product_option UNIQUE NULLS NOT DISTINCT (user_id, product_id, option_id)
);

-- ==============================================================================
-- [테이블 7] orders (주문)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL UNIQUE,
    total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
    discount_amount INTEGER NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    shipping_fee INTEGER NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
    final_amount INTEGER NOT NULL CHECK (final_amount >= 0),
    status TEXT NOT NULL DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'PAID', 'PREPARING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED')),
    shipping_name TEXT NOT NULL,
    shipping_phone TEXT NOT NULL,
    shipping_address TEXT NOT NULL,
    shipping_memo TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 8] order_items (주문 상세 품목)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id BIGINT REFERENCES public.products(id) ON DELETE SET NULL,
    option_id BIGINT REFERENCES public.product_options(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    option_name TEXT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price INTEGER NOT NULL CHECK (unit_price >= 0),
    subtotal_price INTEGER NOT NULL CHECK (subtotal_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 9] refunds (환불 / 반품 신청)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.refunds (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    order_item_id BIGINT REFERENCES public.order_items(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    refund_amount INTEGER NOT NULL CHECK (refund_amount >= 0),
    status TEXT NOT NULL DEFAULT 'REQUESTED' 
        CHECK (status IN ('REQUESTED', 'APPROVED', 'REJECTED', 'COMPLETED')),
    admin_memo TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 10] notifications (회원 알림)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'INFO' 
        CHECK (type IN ('ORDER', 'SHIPPING', 'PROMOTION', 'SYSTEM', 'INFO')),
    link_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- [테이블 11] reviews (상품 리뷰)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_item_id BIGINT REFERENCES public.order_items(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    content TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ==============================================================================
-- [트리거 & 함수 1] 소셜/이메일 로그인 시 profiles 자동 생성 (handle_new_user)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    user_name TEXT;
    avatar TEXT;
BEGIN
    -- 소셜 로그인(구글, 카카오 등) 및 이메일 가입 메타데이터 파싱
    user_name := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'user_name',
        split_part(NEW.email, '@', 1)
    );
    avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture'
    );

    INSERT INTO public.profiles (id, email, name, avatar_url, grade, total_spent, role)
    VALUES (
        NEW.id,
        NEW.email,
        user_name,
        avatar,
        'BRONZE',
        0,
        'customer'
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, public.profiles.name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- auth.users 테이블에 트리거 연결
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ==============================================================================
-- [트리거 & 함수 2] 고객 등급 자동 업데이트 함수 (update_customer_grade)
-- ==============================================================================
-- 등급 산정 기준:
-- BRONZE: 0원 이상
-- SILVER: 100,000원 이상
-- GOLD:   300,000원 이상
-- VIP:    500,000원 이상
CREATE OR REPLACE FUNCTION public.update_customer_grade(target_user_id UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    calculated_total INTEGER := 0;
    new_grade TEXT := 'BRONZE';
BEGIN
    -- 결제 완료 이상 상태인 유효 주문의 총 결제 금액 계산
    SELECT COALESCE(SUM(final_amount), 0)
    INTO calculated_total
    FROM public.orders
    WHERE user_id = target_user_id
      AND status IN ('PAID', 'PREPARING', 'SHIPPED', 'DELIVERED');

    -- 총 누적 구매 금액에 따른 등급 산정
    IF calculated_total >= 500000 THEN
        new_grade := 'VIP';
    ELSIF calculated_total >= 300000 THEN
        new_grade := 'GOLD';
    ELSIF calculated_total >= 100000 THEN
        new_grade := 'SILVER';
    ELSE
        new_grade := 'BRONZE';
    END IF;

    -- 회원 프로필 갱신
    UPDATE public.profiles
    SET 
        total_spent = calculated_total,
        grade = new_grade,
        updated_at = NOW()
    WHERE id = target_user_id;
END;
$$;

-- 주문 변경 시 고객 등급 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION public.trigger_order_grade_update()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM public.update_customer_grade(OLD.user_id);
    ELSE
        PERFORM public.update_customer_grade(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$;

-- orders 테이블에 등급 자동 갱신 트리거 연결
DROP TRIGGER IF EXISTS on_order_status_change_grade ON public.orders;
CREATE TRIGGER on_order_status_change_grade
    AFTER INSERT OR UPDATE OF status, final_amount OR DELETE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.trigger_order_grade_update();


-- ==============================================================================
-- [트리거 3] updated_at 자동 갱신 연결
-- ==============================================================================
CREATE OR REPLACE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE OR REPLACE TRIGGER set_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE OR REPLACE TRIGGER set_carts_updated_at BEFORE UPDATE ON public.carts FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE OR REPLACE TRIGGER set_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE OR REPLACE TRIGGER set_refunds_updated_at BEFORE UPDATE ON public.refunds FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE OR REPLACE TRIGGER set_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ==============================================================================
-- [Row Level Security (RLS) 보안 정책 설정]
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 1) profiles: 본인 프로필 조회 및 수정 가능, 전체 조회는 공개(닉네임 등)
CREATE POLICY "프로필은 누구나 조회 가능" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "본인 프로필만 수정 가능" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2) categories & products & options & images: 누구나 조회 가능
CREATE POLICY "카테고리는 누구나 조회 가능" ON public.categories FOR SELECT USING (true);
CREATE POLICY "상품은 누구나 조회 가능" ON public.products FOR SELECT USING (status != 'HIDDEN');
CREATE POLICY "상품 옵션은 누구나 조회 가능" ON public.product_options FOR SELECT USING (true);
CREATE POLICY "상품 이미지는 누구나 조회 가능" ON public.product_images FOR SELECT USING (true);

-- 3) carts: 본인 장바구니만 CRUD 가능
CREATE POLICY "본인 장바구니만 조회" ON public.carts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "본인 장바구니 추가" ON public.carts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "본인 장바구니 수정" ON public.carts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "본인 장바구니 삭제" ON public.carts FOR DELETE USING (auth.uid() = user_id);

-- 4) orders & order_items: 본인 주문 내역만 조회 및 생성
CREATE POLICY "본인 주문만 조회" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "본인 주문 생성" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "본인 주문 품목 조회" ON public.order_items FOR SELECT 
USING (EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));
CREATE POLICY "본인 주문 품목 생성" ON public.order_items FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

-- 5) refunds: 본인 환불 내역만 조회 및 신청
CREATE POLICY "본인 환불 내역 조회" ON public.refunds FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "본인 환불 신청 생성" ON public.refunds FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6) notifications: 본인 알림만 조회 및 읽음 처리
CREATE POLICY "본인 알림만 조회" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "본인 알림 상태 수정" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- 7) reviews: 누구나 조회 가능, 작성 및 수정은 본인만
CREATE POLICY "리뷰는 누구나 조회 가능" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "본인만 리뷰 작성 가능" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "본인만 리뷰 수정 가능" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "본인만 리뷰 삭제 가능" ON public.reviews FOR DELETE USING (auth.uid() = user_id);


-- ==============================================================================
-- [기본 카테고리 초기 데이터 (선택 사항)]
-- ==============================================================================
INSERT INTO public.categories (name, slug, sort_order)
VALUES 
    ('OUTER', 'outer', 1),
    ('TOP', 'top', 2),
    ('BOTTOM', 'bottom', 3),
    ('SHOES', 'shoes', 4),
    ('ACC', 'acc', 5)
ON CONFLICT (slug) DO NOTHING;
