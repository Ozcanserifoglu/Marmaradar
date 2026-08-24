import { Link } from 'react-router-dom'
import '../pages/Legal.css'

export default function ApkDisclaimer({ className = 'apk-disclaimer' }) {
  return (
    <p className={className}>
      Bu dosya Google Play’den gelmez; bilinmeyen kaynaklardan kurulum gerektiren bir beta APK’dır.
      İndirerek, kurarak veya kullanarak{' '}
      <Link to="/kullanim-sartlari">Kullanım Şartları</Link>’nı kabul etmiş olursun. Cihazına,
      verilerine, trafikteki sonuçlarına ve uygulamadan kaynaklanan her türlü zarara ilişkin tüm
      risk ve sorumluluk sana aittir. Marmaradar hiçbir sonuç için sorumluluk kabul etmez.{' '}
      <Link to="/gizlilik">Gizlilik</Link>
    </p>
  )
}
