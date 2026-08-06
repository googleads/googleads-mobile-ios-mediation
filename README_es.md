# SDK de Google Mobile Ads para iOS

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | [日本語](./README_ja.md) | **Español**
<!-- hy-mt2-i18n:end -->


El Google Mobile Ads SDK representa la última generación de publicidad móvil de Google, con formatos publicitarios mejorados y API optimizadas que permiten el acceso a redes publicitarias y soluciones de publicidad para dispositivos móviles. Este SDK permite a los desarrolladores de aplicaciones móviles maximizar la rentabilidad de sus aplicaciones nativas.

Este repositorio está dividido en dos secciones:

## Proyecto de adaptador de ejemplo y evento personalizado

Este repositorio contiene el código fuente de un proyecto de ejemplo que muestra cómo una red publicitaria puede integrarse en AdMob Mediation. Hay cuatro componentes principales:

- **Sample SDK** - Se trata de un SDK simulado que sirve como sustituto de un SDK real de red publicitaria. Este proyecto tiene como objetivo mostrar a los desarrolladores cómo utilizar eventos personalizados y adaptadores de mediación para adaptar los SDKs de otras redes publicitarias; por lo tanto, aquí se utiliza uno falso.  
- **Custom Event** - Una clase de evento personalizado de ejemplo que solicitará anuncios al Sample SDK y los transmitirá al Google Mobile Ads SDK.  
- **Adapter** - Un adaptador de mediación de ejemplo que también solicitará anuncios al Sample SDK y los transmitirá al Google Mobile Ads SDK.  
- **MediationExample** - Una aplicación sencilla de una sola vista que muestra anuncios cargados a través del adaptador y el evento personalizado. Puede utilizarse para probar la funcionalidad de ambos.

Si acaba de comenzar a desarrollar eventos personalizados o adaptadores, puede reemplazar el código dentro de las clases de adaptador y/o eventos personalizados de este proyecto y, siempre y cuando no modifique los *nombres* de esas dos clases, probar su propia implementación. Las unidades publicitarias incluidas en el proyecto están vinculadas a los nombres de las clases de adaptador y eventos personalizados.

### Compilación del proyecto de ejemplo

Para compilar el proyecto, siga estos pasos:

1. Descargue o clone el código fuente en su ordenador local.  
2. Ejecute ‘pod update’ en el directorio raíz del proyecto (esto descargará el SDK).  
3. Abra el archivo del espacio de trabajo en Xcode.  
4. Ejecute el proyecto.

## Adaptadores de mediación

Adaptadores de código abierto para la mediación a través del SDK de Google Mobile Ads. Se puede encontrar una lista de estos adaptadores en nuestra página de
[Mediación](https://developers.google.com/admob/ios/mediation#choosing_your_mediation_networks).

# Descargas

Para obtener versiones ya preparadas de estos adaptadores, visite nuestro
[sitio para desarrolladores de mediación](https://developers.google.com/admob/ios/mediate#mediation-networks). Elija la guía correspondiente a una red publicitaria en particular y busque los enlaces de descarga en el Changelog. Las guías de las redes publicitarias también explican cómo incluir adaptadores mediante CocoaPods.

# Documentación

Visite nuestro
[sitio para desarrolladores](https://developers.google.com/admob/ios) para obtener documentación sobre el uso del SDK, y nuestra
[guía para desarrolladores de mediación](https://developers.google.com/admob/ios/mediation-developer) para conocer cómo crear un adaptador.
También puede unirse a la comunidad de desarrolladores en
[nuestro foro](https://groups.google.com/forum/#!forum/google-admob-ads-sdk).

# Sugerir mejoras

Para reportar errores, hacer solicitudes de nuevas funcionalidades o proponer otras mejoras, por favor utilice el [tracker de problemas de GitHub](https://github.com/googleads/googleads-mobile-ios-mediation/issues).

# Licencia

[Licencia Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)
