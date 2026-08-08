# FinTrack Web — Control de Cuentas

Versión web de **FinTrack**, una app para llevar el control de cuentas por pagar (gastos pendientes y pagados), organizarlos por categorías y sincronizarlos con la app Android a través de la red local.

## ⚠️ Aviso importante

**Este es un experimento personal.**

No es un producto comercial ni pretende serlo: no cuenta con soporte, ni garantías de ningún tipo, y puede contener errores. Fue creado con fines de aprendizaje y para uso propio. Úsalo bajo tu propia responsabilidad.

## ¿Qué hace?

- Registra cuentas por pagar y marca su estado (pendiente / pagado).
- Organiza los gastos por categorías con resúmenes y totales.
- Se sincroniza con la app Android FinTrack mediante WebSocket en la red local (LAN).
- Guarda los datos localmente en el navegador (localStorage).

## ¿Cómo usarla?

1. Abre esta página en el navegador.
2. Ve a **Configuración** e ingresa la dirección del servidor de sincronización
   (por ejemplo `ws://192.168.1.10:8080`) para conectarte con la app Android.
3. Los datos se guardan en tu navegador y se sincronizan mientras estés conectado.

## Notas

- **Demo oficial:** esta versión web está publicada en
  <https://lorspi.github.io/FinTrack/>.
- Este build está preparado para funcionar desde un **subdirectorio**
  (por ejemplo `https://usuario.github.io/FinTrack/`), sin necesidad de estar en el dominio raíz.
- Todos los datos viven en tu navegador y en tu dispositivo Android:
  **no hay servidores en la nube ni base de datos remota**.

---

*Proyecto personal con fines experimentales.*
