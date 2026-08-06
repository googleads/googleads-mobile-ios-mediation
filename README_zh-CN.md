# iOS版Google移动广告SDK

<!-- hy-mt2-i18n:start -->
[English](./README.md) | **中文** | [日本語](./README_ja.md) | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


Google Mobile Ads SDK 是谷歌移动广告领域的最新一代产品，它拥有经过优化的广告格式以及简化的 API，可帮助开发者接入各类移动广告网络与广告解决方案。该 SDK 能让移动应用开发者在其原生移动应用中实现最大的盈利潜力。

该仓库分为两个部分：

## 示例适配器与自定义事件项目

该仓库包含一个示例项目的源代码，用于演示广告网络如何接入 AdMob Mediation。该项目由四个主要组件构成：

- **Sample SDK** — 这是一个用于替代真实广告网络 SDK 的模拟 SDK。该项目的目的是向开发者展示如何使用自定义事件和中介适配器来适配其他广告网络的 SDK，因此这里我们使用了模拟版本。
- **Custom Event** — 一个示例自定义事件类，它会从 Sample SDK 请求广告并将其传递给 Google Mobile Ads SDK。
- **Adapter** — 一个示例中介适配器，它同样会从 Sample SDK 请求广告并将其传递给 Google Mobile Ads SDK。
- **MediationExample** — 一个简单的单界面应用，用于展示通过适配器和自定义事件加载的广告，可用于测试两者的功能。

如果您刚开始开发自定义事件或适配器，可以替换该项目中适配器和/或自定义事件类内的代码，并在（不更改这两个类的*名称*的前提下）测试您自己的实现。该项目提供的广告单元是与适配器及自定义事件类的名称相关联的。

### 构建示例项目

要构建该项目，请按照以下步骤操作：

1. 将源代码下载到或克隆到您的本地机器上。
2. 在项目的根目录中运行‘pod update’命令（这将下载 SDK）。
3. 在 Xcode 中打开该工作区文件。
4. 运行该项目。

## 中介适配器

用于通过 Google Mobile Ads SDK 进行中介处理的开源适配器。这些适配器的列表可在我们的
[中介处理](https://developers.google.com/admob/ios/mediation#choosing_your_mediation_networks)
页面上查看。

# 下载

如需这些适配器的预构建版本，请访问我们的
[中介化开发页面](https://developers.google.com/admob/ios/mediate#mediation-networks)。选择某个广告网络的指南，然后在更新日志中查找下载链接。这些广告网络指南还会介绍如何通过 CocoaPods 引入适配器。

# 文档资料

请访问我们的
[开发者网站](https://developers.google.com/admob/ios)，查看有关使用该 SDK 的文档；同时可参阅我们的
[中介适配器开发指南](https://developers.google.com/admob/ios/mediation-developer)，了解如何创建适配器。您还可以加入开发者社区，访问
[我们的论坛](https://groups.google.com/forum/#!forum/google-admob-ads-sdk)。

# 提出改进建议

如需提交错误报告、提出功能需求或其他改进建议，请使用[github的issue跟踪系统](https://github.com/googleads/googleads-mobile-ios-mediation/issues)。

# 许可证

[Apache 2.0 许可证](http://www.apache.org/licenses/LICENSE-2.0.html)
