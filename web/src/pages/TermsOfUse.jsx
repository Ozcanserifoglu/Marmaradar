import { Link } from 'react-router-dom'
import LegalLayout from '../components/LegalLayout'

export default function TermsOfUse() {
  return (
    <LegalLayout title="Kullanım Şartları">
      <section className="legal-callout">
        <h2>Kabul</h2>
        <p>
          Marmaradar web sitesini veya uygulamasını kullandığın anda bu şartların tamamını
          okuduğunu ve kabul ettiğini beyan edersin. Marmaradar, sitenin veya uygulamanın
          kullanımından doğan hiçbir sonuç için sorumluluk kabul etmez. Cihaz hasarı, veri
          kaybı, yanlış veya eksik kamera bilgisi, trafik cezası, kaza, yaralanma, maddi veya
          manevi zarar dahil her türlü sonuç tamamen senin sorumluluğundadır. Uygulamayı
          “olduğu gibi” ve “mevcut haliyle” sunuyoruz; açık veya zımni hiçbir garanti
          vermiyoruz.
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
        <h2>Harita ve OpenStreetMap verisi</h2>
        <p>
          Uygulamadaki arka plan haritası Google Haritalar üzerinden sunulur. EDS / hız kamerası
          ve ortalama hız koridoru noktalarının önemli bir kısmı{' '}
          <a
            href="https://www.openstreetmap.org/copyright"
            target="_blank"
            rel="noopener noreferrer"
          >
            OpenStreetMap
          </a>{' '}
          katkıcılarının verilerinden türetilmiştir. Bu veriler{' '}
          <a
            href="https://opendatacommons.org/licenses/odbl/"
            target="_blank"
            rel="noopener noreferrer"
          >
            Open Database License (ODbL)
          </a>{' '}
          altındadır. OpenStreetMap telif ve lisans bilgileri:{' '}
          <a
            href="https://www.openstreetmap.org/copyright"
            target="_blank"
            rel="noopener noreferrer"
          >
            openstreetmap.org/copyright
          </a>
          .
        </p>
      </section>

      <section>
        <h2>Uygulama mağazaları</h2>
        <p>
          Android sürümünü yalnızca Google Play üzerinden indir. App Store sürümü henüz
          yayınlanmamış olabilir. Üçüncü taraf sitelerden veya dosya paylaşımından gelen
          paketlerden Marmaradar sorumlu değildir.
        </p>
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
          Hesabı askıya alabilir veya kapatabiliriz. Hesabını istediğin zaman uygulamadan veya{' '}
          <Link to="/hesap-sil">hesap silme sayfasından</Link> silebilirsin. Kişisel veriler{' '}
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
          Siteyi veya uygulamayı kullanmak istemiyorsan kullanmayı bırak; uygulamayı
          cihazından kaldır.
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
