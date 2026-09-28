"""
[화면 렌더링 테스트 스크립트]
초보자 가이드:
실제 서버를 띄우지 않고도 Flask의 test_client 기능을 사용하면,
홈페이지가 200 OK 정상 응답을 반환하는지,
VIBE-FASHION 브랜드명과 더미 상품 4개가 화면에 정상적으로 표시되는지 즉시 검증할 수 있습니다.

실행 방법:
    python test_app.py
"""

from app import create_app


def test_home_page():
    print("\n--- [VIBE-FASHION 화면 렌더링 테스트 시작] ---")
    app = create_app()
    app.config["TESTING"] = True

    with app.test_client() as client:
        response = client.get("/")
        html = response.data.decode("utf-8")

        # 1. HTTP 응답 상태 코드 확인 (200 OK)
        assert response.status_code == 200, f"페이지 로드 실패! 상태 코드: {response.status_code}"
        print("✔ 1. HTTP 200 OK 응답 확인 완료")

        # 2. 브랜드 로고 텍스트 확인
        assert "VIBE-FASHION" in html, "브랜드 이름 'VIBE-FASHION'이 화면에 없습니다."
        print("✔ 2. 'VIBE-FASHION' 브랜드명 및 네비게이션 렌더링 확인 완료")

        # 3. Bootstrap 5.3 CDN 링크 확인
        assert "bootstrap@5.3.3" in html, "Bootstrap 5.3 CDN이 누락되었습니다."
        print("✔ 3. Bootstrap 5.3.3 CDN 로드 확인 완료")

        # 4. 히어로 섹션 키워드 확인
        assert "2026 S/S NEW COLLECTION" in html, "히어로 섹션이 정상 렌더링되지 않았습니다."
        print("✔ 4. 히어로 섹션(배너 및 헤드라인) 렌더링 확인 완료")

        # 5. picsum.photos 더미 상품 카드 4개 확인
        assert "picsum.photos" in html, "picsum.photos 이미지가 없습니다."
        assert "오버핏 빈티지 데님 자켓" in html, "더미 상품 1번 누락"
        assert "미니멀 실루엣 코튼 셔츠" in html, "더미 상품 2번 누락"
        assert "와이드 핏 턱 슬랙스" in html, "더미 상품 3번 누락"
        assert "클래식 레더 크로스백" in html, "더미 상품 4번 누락"
        print("✔ 5. picsum.photos 더미 상품 카드 4개 정상 출력 확인 완료")

    print("--- [테스트 완료: 모든 화면 요소가 정상적으로 구성되어 있습니다!] ---\n")


if __name__ == "__main__":
    test_home_page()
