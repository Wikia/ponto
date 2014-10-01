Pod::Spec.new do |s|
  s.name             = "Ponto"
  s.version          = "0.1.1"
  s.summary          = "Ponto is comunication bridge between HTML and Native."
  s.description      = <<-DESC
                       Ponto is comunication bridge between HTML and Native.
                       With Ponto you can call native methods from JS inside WebView, or call JS methods from native code.
                       DESC
  s.homepage         = "https://github.com/Wikia/ponto"
  s.license          = "MIT"
  s.authors          = { "Grzegorz Nowicki" => "grzegorz@wikia-inc.com" }
  s.platform         = :ios, '7.0'
  s.source_files     = 'ios/Ponto/PontoLib/*.{h,m}'
  s.source           = { :git => "https://github.com/Wikia/ponto.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.framework = WebKit

end
