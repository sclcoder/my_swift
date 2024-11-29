//
//  RichTextEditorVeiw.swift
//  my_swift
//
//  Created by Sun ChunLei (Lofty Team) on 2024/11/15.
//

import UIKit
import WebKit

class RichTextEditorVeiwController: UIViewController, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        setupWebView()
        
        loadEditor()
    }
    
    private func setupNavigationBar() {
        self.navigationItem.title = "Editor"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "reload", style: .plain, target: self, action: #selector(reload(item:)))
    }
    
    @objc private func reload(item: UIBarButtonItem) {
        print("reload")
        
        loadEditor()
    }
    
    
    // 初始化 WKWebView
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        
        // 允许 JavaScript 与 Swift 通信
        let contentController = WKUserContentController()
        contentController.add(self, name: "editorHandler")
        webConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: self.view.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .red
        self.view.addSubview(webView)
    }
    
    // 加载 editor.html 文件
    private func loadEditor() {
        if let htmlPath = Bundle.main.path(forResource: "quill", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // 处理从 JavaScript 发来的消息
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "editorHandler", let editorContent = message.body as? String {
            print("Received content from editor: \(editorContent)")
        }
    }
    
    // 获取编辑器内容（从 Swift 调用 JavaScript）
    func getEditorContent() {
        webView.evaluateJavaScript("getEditorContent();") { result, error in
            if let content = result as? String {
                print("Editor content: \(content)")
            } else if let error = error {
                print("Error getting content: \(error.localizedDescription)")
            }
        }
    }
}

