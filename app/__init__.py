"""
[VIBE-FASHION 쇼핑몰 - 애플리케이션 팩토리 모듈]
초보자 가이드:
Flask에서는 애플리케이션 객체를 전역 변수로 바로 생성하기보다,
함수 안에서 생성하여 반환하는 '앱 팩토리 패턴(Application Factory Pattern)'을 권장합니다.
이 방식을 사용하면 테스트, 다양한 설정 적용, 블루프린트 등록이 깔끔해집니다.
"""

import os
from flask import Flask
from dotenv import load_dotenv

# .env 파일에서 환경 변수를 로드합니다.
load_dotenv()


def create_app():
    """
    Flask 애플리케이션 인스턴스를 생성하고 초기 설정을 진행하는 팩토리 함수입니다.
    
    Returns:
        Flask: 설정과 라우트가 등록된 Flask 앱 객체
    """
    # 1. Flask 애플리케이션 객체 생성
    # __name__은 현재 모듈의 이름을 의미하며, Flask가 템플릿과 정적 파일을 찾는 기준 경로가 됩니다.
    app = Flask(__name__)

    # 2. 애플리케이션 기본 환경 설정
    # 세션 암호화 등에 사용되는 비밀키를 지정합니다.
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "vibe-fashion-default-secret-key")

    # 3. 블루프린트(Blueprint) 등록
    # routes 폴더에서 분리된 메인 라우트(URL 처리기)를 가져와 앱에 등록합니다.
    from app.routes.main import main_bp
    app.register_blueprint(main_bp)

    return app
