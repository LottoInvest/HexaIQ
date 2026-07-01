import 'package:flutter/material.dart';

import '../../../app/version_info.dart';

enum PolicyDocumentType {
  privacy(title: '개인정보처리방침', body: _privacyBody),
  terms(title: '이용약관', body: _termsBody);

  const PolicyDocumentType({required this.title, required this.body});

  final String title;
  final String body;
}

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.type});

  final PolicyDocumentType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  type.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'HexaIQ v${VersionInfo.current.version}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 20),
                Text(type.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _privacyBody = '''
HexaIQ는 사용자의 인지 검사 경험을 제공하기 위해 필요한 최소한의 정보만 처리합니다.

수집 및 저장 항목
- 프로필 이름, 연령대, 학년 등 사용자가 직접 입력한 기본 프로필
- 검사 종류, 문항 ID, 선택 답안, 정답 여부, 응답 시간
- 영역별 점수, 추정 IQ, 상위 비율, 리포트 생성 정보
- 광고 표시 및 결제 완료 여부
- 앱 안정성 개선을 위한 비식별 이벤트

수집 목적
- 검사 진행, 결과 리포트 생성, 검사 이력 저장
- 전문 검사 구매 상태 확인
- 광고 표시 흐름 관리
- 앱 오류 확인 및 품질 개선

처리하지 않는 정보
- 결제 카드 번호 등 결제 수단의 민감 정보
- 사용자가 풀이 메모에 입력한 내용의 서버 전송
- 건강 정보, 정확한 위치 정보, 불필요한 민감 정보

보관 및 삭제
검사 결과와 설정 정보는 기본적으로 기기 내 로컬 저장소에 보관됩니다. 사용자는 앱 삭제 또는 향후 제공되는 데이터 삭제 기능을 통해 저장 정보를 삭제할 수 있습니다.

광고 및 결제
무료 검사에는 일부 광고가 포함될 수 있습니다. 전문 검사는 일회성 인앱 결제로 제공되며 결제 처리는 앱 마켓의 결제 시스템을 통해 수행됩니다.

문의
개인정보 관련 문의는 설정 화면의 문의하기를 통해 접수할 수 있습니다.
''';

const _termsBody = '''
HexaIQ는 사용자의 문제 해결 방식과 인지 영역별 경향을 참고용으로 확인할 수 있도록 돕는 앱입니다.

검사 결과의 성격
HexaIQ의 결과는 자기 이해와 학습 참고를 위한 정보이며, 의료적·임상적·교육기관의 공식 진단을 대체하지 않습니다.

광고
무료 검사에는 일부 구간에서 광고가 표시될 수 있습니다. 광고 로딩에 실패하더라도 가능한 경우 검사 흐름은 계속 진행됩니다.

전문 검사 및 결제
전문 검사는 USD \$4.90 일회성 인앱 결제로 제공됩니다. 결제 완료 후 전문 검사와 전문 PDF 리포트 기능에 접근할 수 있습니다. 구독 상품이 아니며 반복 결제되지 않습니다.

PDF 리포트
PDF 리포트는 검사 결과를 저장하거나 공유하기 위한 편의 기능입니다. 기기의 공유 환경 또는 저장 권한 상태에 따라 일부 기능이 제한될 수 있습니다.

사용자 책임
사용자는 검사 결과를 참고 자료로 활용해야 하며, 중요한 의사결정에는 전문가의 조언을 함께 고려해야 합니다.

서비스 변경
앱 안정성 개선, 정책 준수, 스토어 심사 대응을 위해 문구나 기능 제공 방식이 변경될 수 있습니다.
''';
