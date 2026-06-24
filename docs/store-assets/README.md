# 스토어 그래픽 자산

라이트+블루 브랜딩(1.0.0+4 기준). 이전 에스프레소 갈색 버전은 git 히스토리에 보존.

| 파일 | 용도 | 비고 |
|---|---|---|
| `icon_512.png` | Play 스토어 앱 아이콘 512×512 | 현재 앱 아이콘(블루+흰 캡슐) 1024에서 다운스케일 |
| `feature_graphic_1024x500.jpg` | Play 스토어 피처 그래픽 | `feature_graphic.html`을 헤드리스 Chrome으로 렌더 |
| `feature_graphic.html` | 피처 그래픽 소스 | 문구/색 수정 후 재렌더 |

## 피처 그래픽 재생성
```sh
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --force-device-scale-factor=1 \
  --window-size=1024,500 --screenshot=fg.png \
  "file://$PWD/docs/store-assets/feature_graphic.html"
sips -s format jpeg -s formatOptions 92 fg.png --out docs/store-assets/feature_graphic_1024x500.jpg
```

## 아이콘 재생성 (앱 아이콘 변경 시)
```sh
sips -z 512 512 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png \
  --out docs/store-assets/icon_512.png
```
