// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Константы для тестирования модуля лицензирования
class TestConstants {
  // Тестовый публичный ключ для проверки подписи лицензии
  static const publicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtlwatfQBSfYEbCYMTRnkZRnUtdtD/BgFGcQEXFxV1ywWCZ/6gmj4+qcZSueQ1jhnoFYk+tDVTeAxvxFRkfoxjEzdOaaIyKpM6ING3NS6JW1NfjhWalQ30FM0IfjsDK1ByghNffY+MaH1ObGOQV+0Tg5GNXWXdFwHSdy2IlBe9q+2PQAfK0J0g/vXa84T4w6Lzy1J7x0qNEN05J74SAGgnvDdDtUuuIeQIvYpUwrYiB+B2zpO5aLGQAAKxtjvMwJy4TJLMcJhHWvLxeaX5FcDey4Nmu90hiKyura34MzTR0r4OpeOj8GHw/Q0Q5yS6aN+ihMERc1OTMptYP85OylpwQIDAQAB
-----END PUBLIC KEY-----''';

  // Тестовый приватный ключ для создания подписи лицензии
  static const privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC2XBq19AFJ9gRsJgxNGeRlGdS120P8GAUZxARcXFXXLBYJn/qCaPj6pxlK55DWOGegViT60NVN4DG/EVGR+jGMTN05pojIqkzog0bc1LolbU1+OFZqVDfQUzQh+OwMrUHKCE199j4xofU5sY5BX7RODkY1dZd0XAdJ3LYiUF72r7Y9AB8rQnSD+9drzhPjDovPLUnvHSo0Q3TknvhIAaCe8N0O1S64h5Ai9ilTCtiIH4HbOk7losZAAArG2O8zAnLhMksxwmEda8vF5pfkVwN7Lg2a73SGIrK6trfgzNNHSvg6l46PwYfD9DRDnJLpo36KEwRFzU5Mym1g/zk7KWnBAgMBAAECggEAVJOwMb6LEH4BPBWDdAjztG5ACN46kEOlrfcLHLkYePTx/aHMgkpkW4A/i02OD8TWTvdVLFzJ6VX3TIogPmd/LnaBzhiubP8LL3WfWpFxCiXBIK7JaYRI5J6KWc1E0XZTwnuKUUbxPnzCqvDuLOTRz7fwGSBCT83U9Y1fjdefy6IWyN97N+TlwiOgtnxUvRFRXyZSs6E4lQ7QII/mtNyLePEHy5y38FfKhuj6nSwvHE0M7aSoRFIcu6JlGWD97WhxybOEMCg6oswSw1G0Bi6JhUwAUryirHpWp8XOwZIxHhQNVTKybjAMt8JrrkVC+0orYMF54IbT4/D53EwE1e6ErwKBgQDs/FM6OXKeDqewFsmXdDLeHmV5jNS0sQM4hWuANu6AJMeBmU268vcFEhvgcoEh3arb/emebI5SIuWLFFgaKVs7tz1EZC+eBWGthj/tOyLZB+CIKfhnDrlJ+bByc+Jal/7YcUq1MyLV/MhynN/LH0Ky8KtrVKzLt2rtae1SM7FvTwKBgQDE/cQxn0sdF3RpjBlXjXoW/ZlC0FrPN1zYRh6EKtYfD/b6Lz6yHga8BMzhYN7GwKfNkvMkxKzeBI9Sk6OTZ1B/cnH/YargeqVjD0pdIFDMyH+XP4sYqKLCfQtR80+b6KOfymDESCDsz790YRtGySbBfjxOQdPmzFRlkCiryG3R7wKBgAS2M5VpxPydf/oBSfrH5acC5bOX+DarekvqYyvGa9GCabEK8j+wSvb/2CwLOsQImzgKgVWUBPRfGz87pVDH17eFOiOc9lFm+/0uOSEnVtcH0BAE/ZpW8Zol67sq0KpKcVeuUPTvUlb80qNsuQpZ0cKrBE16/oCCYg7cV0qWGoYDAoGAPbAmP0/d6tdMej0INpW0VPzHgNfUiC2TIpsatVLgyMtsET64SHkErN5n9nAqc10jb0oEYFBCvif5ZeecAu4IlFCXiFzicPeXUSUZqX4UL3zeD9QzT96HUZZs9BXYqT859jEfCnh37xDDqMM8EnetbkyEwBD3NcBo8YEqa1kRovsCgYEA4eVC+YLgWoVYPQcf6cqITIPM1Yq8KH2Pmgl0hwXzV0ul63tC+YtwJMbK2+U65udJGLB4UTGnyc2oUNENlTym75K5ItILuuo2h9A4rv9Qksm5mO6j9L7dXQFgSqskkQsDFG063Fehd7ItcWtLa9s37m6b5zFyyUaf9HcIBbawTnk=
-----END RSA PRIVATE KEY-----''';
  // Тестовый идентификатор приложения
  static const appId = 'com.example.app';

  // Срок действия тестовой лицензии (в днях)
  static const defaultLicenseDuration = 30;
}
