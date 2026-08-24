import { Link } from 'react-router-dom'
import LegalLayout from '../components/LegalLayout'

export default function TermsOfUse() {
  return (
    <LegalLayout title="Kullanım Şartları">
      <section className="legal-callout">
        <h2>Beta APK — tüm risk sana aittir</h2>
        <p>
          marmaradar.com üzerinden APK’yı indirdiğin, cihazına kurduğun veya Marmaradar’ı
          kullandığın anda bu şartların tamamını okuduğunu ve kabul ettiğini beyan edersin.
          Marmaradar, sitenin, beta uygulamanın, kurulumun veya kullanımdan doğan hiçbir sonuç
          için sorumluluk kabul etmez. Cihaz hasarı, veri kaybı, kötü amaçlı yazılım, işletim
          sistemi / Play Protect uyarıları, güncelleme sorunları, yanlış veya eksik kamera
          bilgisi, trafik cezası, kaza, yaralanma, maddi veya manevi zarar dahil her türlü
          sonuç tamamen senin sorumluluğundadır. Uygulamayı “olduğu gibi” ve “mevcut haliyle”
          sunuyoruz; açık veya zımni hiçbir garanti vermiyoruz.
        </p>
      </section>

      <section>
        <h2>Hizmet nedir?</h2>
        <p>
          Marmaradar, Türkiye’de sabit hız kameraları (EDS) ve ortalama hız koridorları için
          uyarı ve harita bilgisi sunmayı amaçlayan bir sürücü yardımcı uygulamasıdır. Resmî
          bir navigasyon, trafik otoritesi veya ceza sistemi değildir. EGM, KGM veya herhangi
          bir kamu kurumu ile bağlantılı değildir. Kamera ve koridor verileri eksik, gecikmeli
          veya hatalı olabilir.
        </p>
      </section>

      <section>
        <h2>Beta yazılım</h2>
        <p>
          Uygulama beta aşamasındadır. Hatalar, kesintiler, veri kaybı ve geriye dönük uyumsuz
          değişiklikler beklenmelidir. Mağaza sürümü henüz yoktur; özellikler değişebilir veya
          durdurulabilir.
        </p>
      </section>

      <section>
        <h2>APK ve yan yükleme (sideload)</h2>
        <ul>
          <li>
            Dosya Google Play veya başka bir uygulama mağazasından gelmez. Android’de
            “bilinmeyen kaynaklar” izni vermen gerekir; bu, cihaz güvenliğini zayıflatır.
          </li>
          <li>
            Yalnızca <a href="https://www.marmaradar.com">www.marmaradar.com</a> üzerindeki
            resmi indirme bağlantısını kullan. Başka siteden, mesajdan veya dosya paylaşımından
            gelen APK’lardan Marmaradar sorumlu değildir.
          </li>
          <li>
            Play Protect veya antivirüs uygulamayı engelleyebilir veya uyarabilir; bunları
            aşmak senin kararındır ve riski sana aittir.
          </li>
          <li>Otomatik güncelleme yoktur; yeni sürümü kendin indirmen gerekir.</li>
          <li>
            İndirme, kurulum, izinler (konum, bildirim, arka plan) ve kaldırma tamamen senin
            cihazında ve senin kontrolündedir.
          </li>
        </ul>
      </section>

      <section>
        <h2>Güvenli sürüş ve trafik kuralları</h2>
        <p>
          Marmaradar hız yapmak, kuralları ihlal etmek veya dikkati dağıtmak için bir araç
          değildir. Trafik mevzuatına uymak, yolu izlemek ve aracı güvenle kullanmak yalnızca
          sürücünün yükümlülüğüdür. Uyarı kaçırmak veya yanlış bilgi, cezayı veya kazayı
          mazur göstermez. Uygulamayı kullanırken dikkatin yolda olmalıdır.
        </p>
      </section>

      <section>
        <h2>Hesap ve bildirimler</h2>
        <p>
          Hesap oluşturmak isteğe bağlıdır; bazı özellikler (sürüş yükleme, istatistik,
          topluluk raporları) giriş gerektirir. Sahte veya kötü niyetli rapor yasaktır.
          Hesabı askıya alabilir veya kapatabiliriz. Kişisel veriler{' '}
          <Link to="/gizlilik">Gizlilik Politikası</Link>’na tabidir.
        </p>
      </section>

      <section>
        <h2>Sorumluluğun sınırlandırılması</h2>
        <p>
          Kanunların izin verdiği en geniş ölçüde Marmaradar; işletmecisi, katkıda bulunanlar
          ve barındırma sağlayıcıları; doğrudan, dolaylı, arızi, özel veya sonuç olarak ortaya
          çıkan zararlardan, kâr kaybından, veri kaybından, cihaz arızasından, üçüncü taraf
          hizmet kesintilerinden ve uygulamanın veya sitenin kullanımından veya
          kullanılamamasından doğan taleplerden sorumlu tutulamaz. Zorunlu tüketici
          hakların saklıdır; bunlar kanunla kaldırılamayan haklardır.
        </p>
        <p>
          Siteyi veya APK’yı kullanmak istemiyorsan indirme; indirdiysen uygulamayı kaldır ve
          kullanmayı bırak.
        </p>
      </section>

      <section>
        <h2>Fikri mülkiyet</h2>
        <p>
          Site, marka, arayüz ve yazılım Marmaradar’a aittir. İzinsiz kopyalama, tersine
          mühendislik veya yeniden dağıtım yasaktır.
        </p>
      </section>

      <section>
        <h2>Değişiklikler ve iletişim</h2>
        <p>
          Bu şartları güncelleyebiliriz. Güncel metin bu sayfada yayınlanır. Uyuşmazlıklarda
          Türkiye Cumhuriyeti hukuku uygulanır. İletişim:{' '}
          <a href="mailto:marmaradar@gmail.com">marmaradar@gmail.com</a>
        </p>
      </section>
    </LegalLayout>
  )
}
