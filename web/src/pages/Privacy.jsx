import { Link } from 'react-router-dom'
import LegalLayout from '../components/LegalLayout'

export default function Privacy() {
  return (
    <LegalLayout title="Gizlilik Politikası ve KVKK Aydınlatma Metni">
      <section>
        <p>
          Bu metin, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) kapsamında Marmaradar
          uygulaması ve <a href="https://www.marmaradar.com">www.marmaradar.com</a> sitesini kullanan
          kişileri aydınlatmak içindir. Veri sorumlusu, tescilli bir şirket unvanı olmaksızın
          Marmaradar markasıyla faaliyet gösteren işletmecidir.
        </p>
        <p>
          İletişim:{' '}
          <a href="mailto:marmaradar@gmail.com">marmaradar@gmail.com</a>
          {' · '}
          <a href="mailto:support@marmaradar.com">support@marmaradar.com</a>
        </p>
      </section>

      <section>
        <h2>Hangi verileri işliyoruz?</h2>
        <ul>
          <li>
            <strong>Konum:</strong> Harita, EDS ve koridor uyarıları için cihazının GPS verisi
            (ön planda ve, izin verirsen, arka planda). Yakındaki kameralar ve koridorlar için
            hesap oluşturmasan da konum koordinatların sunucuya sorgu olarak gidebilir.
          </li>
          <li>
            <strong>Sürüş kayıtları:</strong> Giriş yaptıysan bir sürüş bittiğinde güzergâh, hız ve
            zaman damgaları sunucuya yüklenebilir; cihazda da geçici olarak saklanabilir.
          </li>
          <li>
            <strong>Hesap:</strong> E-posta ve parola veya Google / Apple ile giriş. Oturum
            jetonları cihazında güvenli depolamada tutulur.
          </li>
          <li>
            <strong>Topluluk bildirimleri:</strong> Giriş yapan kullanıcıların haritaya düşen
            raporları (ör. mobil kamera, trafik olayı) konum ve hesapla ilişkilendirilebilir.
          </li>
          <li>
            <strong>Teknik veriler:</strong> API çağrılarında IP adresi ve benzeri bağlantı
            bilgileri (güvenlik, hız sınırı, gerektiğinde coğrafi kısıtlama).
          </li>
        </ul>
      </section>

      <section>
        <h2>Neden işliyoruz?</h2>
        <p>
          Hizmeti sunmak için: canlı harita, kamera/koridor uyarıları, isteğe bağlı sürüş geçmişi
          ve istatistikler, hesap yönetimi, şifre sıfırlama e-postaları, kötüye kullanımı önleme.
          Reklam ağı veya uygulama içi analitik / çökme SDK’sı kullanmıyoruz.
        </p>
      </section>

      <section>
        <h2>Kimlerle paylaşılıyor?</h2>
        <p>
          Hizmeti işletmek için aşağıdaki üçüncü taraflar devreye girebilir: Google (Haritalar,
          Places, Directions, Roads, Distance Matrix, Geocoding, metin-okuma, Google ile giriş),
          Apple (Apple ile giriş), Resend (işlemsel e-posta). Sitede yazı tipleri Google Fonts
          üzerinden yüklenebilir. Bu taraflar kendi gizlilik politikalarına tabidir.
        </p>
      </section>

      <section>
        <h2>Saklama ve silme</h2>
        <p>
          Veriler hizmeti sağlamak için gerekli olduğu sürece saklanır. Hesap ve sürüş verilerinin
          silinmesini e-posta ile talep edebilirsin; uygulamada henüz otomatik hesap silme yoktur.
          Talepler makul sürede işlenir.
        </p>
      </section>

      <section>
        <h2>Hakların</h2>
        <p>
          KVKK madde 11 kapsamında verilerinin işlenip işlenmediğini öğrenme, düzeltme, silme,
          itiraz ve kanunda sayılan diğer haklarını{' '}
          <a href="mailto:marmaradar@gmail.com">marmaradar@gmail.com</a> adresine yazarak
          kullanabilirsin.
        </p>
      </section>

      <section>
        <h2>Çerezler ve site</h2>
        <p>
          Pazarlama sitesi temel olarak tanıtım ve APK indirme içindir. Zorunlu barındırma /
          güvenlik kayıtları ve Google Fonts dışında pazarlama çerezi kullanmıyoruz. İleride
          eklenirse bu metin güncellenir.
        </p>
      </section>

      <section>
        <h2>Yaş</h2>
        <p>
          Marmaradar sürüşe yönelik bir üründür; 18 yaşından küçüklerin kullanması amaçlanmaz.
        </p>
      </section>

      <section>
        <h2>Uygulama ve şartlar</h2>
        <p>
          Beta APK’yı indirmek ve uygulamayı kullanmak{' '}
          <Link to="/kullanim-sartlari">Kullanım Şartları</Link>’na da tabidir.
        </p>
      </section>
    </LegalLayout>
  )
}
