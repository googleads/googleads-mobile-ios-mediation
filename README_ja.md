# iOS向けGoogle Mobile Ads SDK

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | **日本語** | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


Google Mobile Ads SDKは、より洗練された広告フォーマットや、モバイル広告ネットワークおよび広告ソリューションにアクセスするための効率化されたAPIを備えた、Googleの最新世代モバイル広告SDKです。このSDKにより、モバイルアプリ開発者はネイティブモバイルアプリにおける収益化を最大限に高めることができます。

このリポジトリは2つのセクションに分かれています：

## サンプルアダプターおよびカスタムイベントプロジェクト

このリポジトリには、広告ネットワークがAdMob Mediationにどのように統合できるかを示すサンプルプロジェクトのソースコードが含まれています。主に4つのコンポーネントで構成されています：

- **Sample SDK** – これは実際の広告ネットワークSDKに代わる仮のSDKです。このプロジェクトは、開発者がカスタムイベントやメディエーションアダプタを使って他の広告ネットワークのSDKを適応させる方法を示すためのものであり、ここでは仮のSDKを使用しています。
- **Custom Event** – Sample SDKから広告をリクエストし、それらをGoogle Mobile Ads SDKに渡すためのサンプルとなるカスタムイベントクラスです。
- **Adapter** – Sample SDKから広告をリクエストし、それらをGoogle Mobile Ads SDKに渡すためのサンプルとなるメディエーションアダプタです。
- **MediationExample** – アダプタおよびカスタムイベントを通じて読み込まれた広告を表示する、シンプルな単一ビューアプリケーションです。これを使って両者の機能をテストすることができます。

もしまだカスタムイベントやアダプタの開発を始めたばかりであれば、このプロジェクトに含まれるアダプタおよび/またはカスタムイベントクラス内のコードを置き換え、（これら2つのクラスの*名前*を変更しない限り）自分で実装したものをテストすることができます。プロジェクトに同梱されている広告ユニットは、アダプタクラスとカスタムイベントクラスの名前に基づいて設定されています。

### サンプルプロジェクトのビルド方法

プロジェクトをビルドするには、以下の手順に従ってください：

1. ローカルマシンにソースコードをダウンロードするか、クローンします。
2. プロジェクトのルートディレクトリで‘pod update’を実行します（これによりSDKがダウンロードされます）。
3. Xcodeでワークスペースファイルを開きます。
4. プロジェクトを実行します。

## メディエーションアダプター

Google Mobile Ads SDK を介した仲介処理を実現するためのオープンソースアダプターです。これらのアダプターの一覧は、当社の
[Mediation](https://developers.google.com/admob/ios/mediation#choosing_your_mediation_networks)
ページで確認できます。

# ダウンロード

これらのアダプタの事前構築済みバージョンについては、当社の
[Mediation開発者サイト](https://developers.google.com/admob/ios/mediate#mediation-networks)をご覧ください。
各広告ネットワーク別のガイドを選択し、Changelog内のダウンロードリンクを探してください。広告ネットワークガイドでは、CocoaPodsを使ってアダプタを組み込む方法についても説明されています。

# ドキュメント

SDKの使用方法に関するドキュメントは、当社の
[developer site](https://developers.google.com/admob/ios)をご覧ください。また、アダプタの作成方法については、
[mediation developer guide](https://developers.google.com/admob/ios/mediation-developer)を参照してください。
さらに、
[our forum](https://groups.google.com/forum/#!forum/google-admob-ads-sdk)で開発者コミュニティに参加することもできます。

# 改善案の提案

バグの報告、機能追加のリクエスト、その他の改善案の提案には、[githubのissueトラッカー](https://github.com/googleads/googleads-mobile-ios-mediation/issues)をご利用ください。

# ライセンス

[Apache 2.0 ライセンス](http://www.apache.org/licenses/LICENSE-2.0.html)
