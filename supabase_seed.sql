-- ==============================================================================
-- VIBE-FASHION 쇼핑몰 초기 시드 데이터 (Seed SQL)
-- Supabase SQL Editor에서 실행 가능하도록 작성되었습니다.
-- ==============================================================================

-- 0. 기존 샘플 데이터 정리 (중복 실행 시 충돌 및 중복 방지)
DELETE FROM public.products 
WHERE name IN ('베이직 크롭 티셔츠', '와이드 데님 팬츠', '오버핏 코튼 자켓', '플로럴 미디 원피스');

-- ==============================================================================
-- 1. 카테고리 7개 등록 (ON CONFLICT 적용)
-- ==============================================================================
INSERT INTO public.categories (name, slug, sort_order) VALUES
('상의', 'top', 1),
('하의', 'bottom', 2),
('아우터', 'outer', 3),
('원피스/세트', 'dress', 4),
('액세서리', 'acc', 5),
('가방', 'bag', 6),
('신발', 'shoes', 7)
ON CONFLICT (slug) DO UPDATE 
SET name = EXCLUDED.name,
    sort_order = EXCLUDED.sort_order;


-- ==============================================================================
-- 2. 샘플 상품 4개 등록
-- 참고: 스키마 제약조건(sale_price <= price)에 맞추어 
--       베이직 크롭 티셔츠는 정상가 29,900원 / 할인가 19,900원으로 등록합니다.
-- ==============================================================================
INSERT INTO public.products (category_id, name, description, price, sale_price, badge, status) VALUES
(
    (SELECT id FROM public.categories WHERE slug = 'top'),
    '베이직 크롭 티셔츠',
    '트렌디하고 슬림한 실루엣의 데일리 베이직 크롭 반팔 티셔츠입니다. 다양한 하의와 매치하기 좋습니다.',
    29900,
    19900,
    'SALE',
    'ACTIVE'
),
(
    (SELECT id FROM public.categories WHERE slug = 'bottom'),
    '와이드 데님 팬츠',
    '자연스러운 빈티지 워싱과 멋스러운 실루엣을 자랑하는 사계절용 와이드 데님 팬츠입니다.',
    39900,
    NULL,
    'BEST',
    'ACTIVE'
),
(
    (SELECT id FROM public.categories WHERE slug = 'outer'),
    '오버핏 코튼 자켓',
    '부드러운 프리미엄 코튼 소재로 간절기 시즌 편안하고 감각적으로 걸치기 좋은 오버핏 자켓입니다.',
    59900,
    NULL,
    'NEW',
    'ACTIVE'
),
(
    (SELECT id FROM public.categories WHERE slug = 'dress'),
    '플로럴 미디 원피스',
    '화사한 플라워 패턴과 여성스러운 웨이스트 라인이 돋보이는 플루이드 미디 원피스입니다.',
    45900,
    NULL,
    'HOT',
    'ACTIVE'
);


-- ==============================================================================
-- 3. 상품 썸네일 이미지 등록 (picsum.photos 무료 이미지)
-- ==============================================================================
INSERT INTO public.product_images (product_id, image_url, is_primary, sort_order) VALUES
-- 베이직 크롭 티셔츠 썸네일
(
    (SELECT id FROM public.products WHERE name = '베이직 크롭 티셔츠' ORDER BY id DESC LIMIT 1),
    'https://picsum.photos/id/1025/600/800',
    TRUE,
    1
),
-- 와이드 데님 팬츠 썸네일
(
    (SELECT id FROM public.products WHERE name = '와이드 데님 팬츠' ORDER BY id DESC LIMIT 1),
    'https://picsum.photos/id/338/600/800',
    TRUE,
    1
),
-- 오버핏 코튼 자켓 썸네일
(
    (SELECT id FROM public.products WHERE name = '오버핏 코튼 자켓' ORDER BY id DESC LIMIT 1),
    'https://picsum.photos/id/1062/600/800',
    TRUE,
    1
),
-- 플로럴 미디 원피스 썸네일
(
    (SELECT id FROM public.products WHERE name = '플로럴 미디 원피스' ORDER BY id DESC LIMIT 1),
    'https://picsum.photos/id/64/600/800',
    TRUE,
    1
);


-- ==============================================================================
-- 4. 첫 번째 상품(베이직 크롭 티셔츠) 옵션 9개 등록
-- 색상 (블랙, 화이트, 베이지) × 사이즈 (S, M, L)
-- ==============================================================================
INSERT INTO public.product_options (product_id, color, size, additional_price, stock_quantity)
SELECT 
    p.id,
    c.color,
    s.size,
    0 AS additional_price,
    50 AS stock_quantity
FROM 
    (SELECT id FROM public.products WHERE name = '베이직 크롭 티셔츠' ORDER BY id DESC LIMIT 1) p
CROSS JOIN 
    (VALUES ('블랙'), ('화이트'), ('베이지')) AS c(color)
CROSS JOIN 
    (VALUES ('S'), ('M'), ('L')) AS s(size);
