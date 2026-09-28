"""
[VIBE-FASHION 메인 라우트 모듈]
초보자 가이드:
블루프린트(Blueprint)는 웹사이트의 기능별로 URL 라우트를 쪼개어 관리할 수 있도록 돕는 기능입니다.
여기서는 메인 페이지 및 기본 페이지 요청을 처리하며,
Supabase의 products 테이블과 연동하여 추천 상품 목록을 가져옵니다.
"""

import os
import sys
import traceback
from dotenv import load_dotenv
from flask import Blueprint, render_template
from supabase import create_client, Client

# .env 파일에서 환경변수를 로드합니다.
load_dotenv()

# 'main'이라는 이름의 블루프린트를 생성합니다.
main_bp = Blueprint("main", __name__)


def get_supabase_client() -> Client | None:
    """
    Supabase 클라이언트를 초기화하여 반환합니다.
    환경변수 SUPABASE_URL 및 SUPABASE_ANON_KEY를 사용합니다.
    """
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_ANON_KEY") or os.getenv("SUPABASE_KEY")

    if not supabase_url or not supabase_key:
        return None

    return create_client(supabase_url, supabase_key)


@main_bp.route("/")
def index():
    """
    메인 홈페이지 라우트:
    Supabase 'products' 테이블에서 추천 상품(is_active=True, is_featured=True) 최대 4개를 조회하여 렌더링합니다.
    - 연결 또는 조회 실패 시 빈 리스트로 대체하여 앱이 중단되지 않도록 보호합니다.
    - 가격은 {:,} 포맷을 적용하여 '19,900원' 형태로 템플릿에 전달합니다.
    """
    products = []

    try:
        supabase = get_supabase_client()
        if not supabase:
            raise ConnectionError(
                "Supabase 설정 오류: SUPABASE_URL 또는 SUPABASE_ANON_KEY 환경변수가 설정되지 않았습니다."
            )

        # is_active=true이고 is_featured=true인 상품 최대 4개 조회
        response = (
            supabase.table("products")
            .select("*")
            .eq("is_active", True)
            .eq("is_featured", True)
            .limit(4)
            .execute()
        )

        raw_products = response.data or []

        for item in raw_products:
            product = dict(item)

            # 가격 포맷팅: {:,} 형태로 변환하여 '19,900원' 형태로 저장
            raw_price = product.get("price", 0)
            try:
                numeric_price = int(raw_price) if raw_price is not None else 0
                product["price"] = f"{numeric_price:,}원"
            except (ValueError, TypeError):
                product["price"] = f"{raw_price}원"

            # thumbnail_url이 없을 경우 image_url 또는 기본 이미지 대체
            if not product.get("thumbnail_url"):
                product["thumbnail_url"] = product.get("image_url", "")

            products.append(product)

    except Exception as e:
        # Supabase 연결 실패 또는 쿼리 오류 발생 시 에러 로그를 터미널에 출력하고 빈 리스트로 대체
        print(f"[Supabase 연동 오류] 상품 목록 조회 실패: {e}", file=sys.stderr)
        traceback.print_exc()
        products = []

    return render_template(
        "index.html",
        products=products,
        brand_name="VIBE-FASHION"
    )

