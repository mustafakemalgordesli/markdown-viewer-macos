# Markdown Viewer

`.md` dosyalarını görüntülemek ve düzenlemek için sade, hızlı bir macOS uygulaması.
Finder'da bir Markdown dosyasına çift tıklayın, doğrudan açılsın.

- Editör, önizleme veya yan yana görünüm (⌘1 / ⌘2 / ⌘3)
- Yazarken canlı güncellenen önizleme
- GitHub tarzı Markdown: tablolar, görev listeleri, üstü çizili yazı, kod blokları
- Açık / koyu tema (macOS görünüm ayarını takip eder)
- Yazı boyutu: ⌘+ / ⌘− / ⌘0

Gereksinim: macOS 14 (Sonoma) veya üzeri. Apple Silicon ve Intel Mac'lerde çalışır.

## Kurulum

1. [Releases](../../releases/latest) sayfasından `MarkdownViewer-x.y.dmg` dosyasını indirin.
2. İndirilen dosyaya çift tıklayın. Açılan pencerede **MarkdownViewer** simgesini **Applications** klasörüne sürükleyin.
3. Launchpad'den ya da Uygulamalar klasöründen **MarkdownViewer**'ı açın.

### "Açılamıyor" / "geliştirici doğrulanamadı" uyarısı çıkarsa

Uygulama Apple tarafından notarize edilmediği için macOS ilk açılışta uyarı verebilir. Bu bir kereliğine yapılır:

1. Uyarıyı **Tamam** ile kapatın.
2. **Sistem Ayarları → Gizlilik ve Güvenlik** bölümünü açın.
3. Aşağıda "MarkdownViewer engellendi" yazısının yanındaki **Yine de Aç** düğmesine basın ve onaylayın.

<details>
<summary>Terminal ile (ileri düzey)</summary>

```bash
xattr -dr com.apple.quarantine /Applications/MarkdownViewer.app
```
</details>

### Çift tıklayınca bu uygulama açılsın

Bilgisayarda `.md` dosyalarını açan başka bir uygulama yoksa bu adım gerekmez. Varsa:

- Uygulamayı açıp menüden **MarkdownViewer → Set as Default App for Markdown…** seçin, **veya**
- Herhangi bir `.md` dosyasına sağ tıklayın → **Bilgi Al** → **Birlikte Aç** bölümünden **MarkdownViewer**'ı seçin → **Tümünü Değiştir**.

## Kaynak koddan derleme

Xcode 16 veya üzeri gerekir.

```bash
./install.sh     # derler, /Applications'a kurar ve .md için varsayılan yapar
./make-dmg.sh    # dist/ altında dağıtıma hazır DMG üretir
```

Ya da `MarkdownViewer.xcodeproj` dosyasını Xcode ile açıp ⌘R ile çalıştırın.

## Yeni sürüm yayınlama

`v` ile başlayan bir etiket gönderin; GitHub Actions DMG'yi derleyip Releases sayfasına ekler:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Apple Developer hesabınız varsa `make-dmg.sh`, `DEVELOPER_ID` ve `NOTARY_PROFILE` ortam değişkenleriyle
uygulamayı imzalayıp notarize eder; bu durumda kullanıcılar yukarıdaki uyarıyı hiç görmez.
