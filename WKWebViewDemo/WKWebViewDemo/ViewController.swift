//
//  ViewController.swift
//  WKWebViewDemo
//
//  Created by huangyibiao on 15/10/26.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
  var webView: WKWebView!
  var progressView: UIProgressView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.edgesForExtendedLayout = .None
    
    // 创建webveiew
    // 创建一个webiview的配置项
    let configuretion = WKWebViewConfiguration()
    
    // Webview的偏好设置
    configuretion.preferences = WKPreferences()
    configuretion.preferences.minimumFontSize = 10
    configuretion.preferences.javaScriptEnabled = true
    // 默认是不能通过JS自动打开窗口的，必须通过用户交互才能打开
    configuretion.preferences.javaScriptCanOpenWindowsAutomatically = false
    
    // 通过js与webview内容交互配置
    configuretion.userContentController = WKUserContentController()
    
    // 添加一个JS到HTML中，这样就可以直接在JS中调用我们添加的JS方法
    let script = WKUserScript(source: "function showAlert() { alert('在载入webview时通过Swift注入的JS方法'); }",
      injectionTime: .AtDocumentStart,// 在载入时就添加JS
      forMainFrameOnly: true) // 只添加到mainFrame中
    configuretion.userContentController.addUserScript(script)
    
    // 添加一个名称，就可以在JS通过这个名称发送消息：
    // window.webkit.messageHandlers.AppModel.postMessage({body: 'xxx'})
    configuretion.userContentController.addScriptMessageHandler(self, name: "AppModel")
    
    self.webView = WKWebView(frame: self.view.bounds, configuration: configuretion)
    
    let url = NSBundle.mainBundle().URLForResource("test", withExtension: "html")
    self.webView.loadRequest(NSURLRequest(URL: url!))
    self.view.addSubview(self.webView);
    
    // 监听支持KVO的属性
    self.webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
    self.webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
    self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
    
    self.webView.navigationDelegate = self
    self.webView.UIDelegate = self
    
    self.progressView = UIProgressView(progressViewStyle: .Default)
    self.progressView.frame.size.width = self.view.frame.size.width
    self.progressView.backgroundColor = UIColor.redColor()
    self.view.addSubview(self.progressView)
    
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "前进", style: .Done, target: self, action: "previousPage")
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "后退", style: .Done, target: self, action: "nextPage")
  }
  
  func previousPage() {
    if self.webView.canGoBack {
      self.webView.goBack()
    }
  }
  
  func nextPage() {
    if self.webView.canGoForward {
      self.webView.goForward()
    }
  }
  
  // MARK: - WKScriptMessageHandler
  func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    print(message.body)
    if message.name == "AppModel" {
      print("message name is AppModel")
    }
  }
  
  // MARK: - KVO
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "loading" {
      print("loading")
    } else if keyPath == "title" {
      self.title = self.webView.title
    } else if keyPath == "estimatedProgress" {
      print(webView.estimatedProgress)
      self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
    }
    
    // 已经完成加载时，我们就可以做我们的事了
    if !webView.loading {
      // 手动调用JS代码
      let js = "callJsAlert()";
      self.webView.evaluateJavaScript(js) { (_, _) -> Void in
        print("call js alert")
      }
      
      UIView.animateWithDuration(0.55, animations: { () -> Void in
        self.progressView.alpha = 0.0;
      })
    }
  }
  
  // MARK: - WKNavigationDelegate
  
  // 决定导航的动作，通常用于处理跨域的链接能否导航。WebKit对跨域进行了安全检查限制，不允许跨域，因此我们要对不能跨域的链接
  // 单独处理。但是，对于Safari是允许跨域的，不用这么处理。
  func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
    print(__FUNCTION__)
    
    let hostname = navigationAction.request.URL?.host?.lowercaseString
    
    print(hostname)
    // 处理跨域问题
    if navigationAction.navigationType == .LinkActivated && !hostname!.containsString(".baidu.com") {
      // 手动跳转
      UIApplication.sharedApplication().openURL(navigationAction.request.URL!)
      
      // 不允许导航
      decisionHandler(.Cancel)
    } else {
      self.progressView.alpha = 1.0
      
      decisionHandler(.Allow)
    }
  }
  
  func webViewWebContentProcessDidTerminate(webView: WKWebView) {
    print(__FUNCTION__)
  }
  
  func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    print(__FUNCTION__)
  }
  
  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    print(__FUNCTION__)
  }
  
  func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    print(__FUNCTION__)
  }
  
func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
  print(__FUNCTION__)
}
  
func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
  print(__FUNCTION__)
}
  
  func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
    print(__FUNCTION__)
  }
  
  func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
    print(__FUNCTION__)
    decisionHandler(.Allow)
  }
  
  func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    print(__FUNCTION__)
    completionHandler(.PerformDefaultHandling, nil)
  }
  
// MARK: - WKUIDelegate
func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
  let alert = UIAlertController(title: "Tip", message: message, preferredStyle: .Alert)
  alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (_) -> Void in
    // We must call back js
    completionHandler()
  }))
  
  self.presentViewController(alert, animated: true, completion: nil)
}

func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
  let alert = UIAlertController(title: "Tip", message: message, preferredStyle: .Alert)
  alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (_) -> Void in
    completionHandler(true)
  }))
  alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (_) -> Void in
    completionHandler(false)
  }))
  
  self.presentViewController(alert, animated: true, completion: nil)
}

func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
  let alert = UIAlertController(title: prompt, message: defaultText, preferredStyle: .Alert)
  
  alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
    textField.textColor = UIColor.redColor()
  }
  alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (_) -> Void in
    completionHandler(alert.textFields![0].text!)
  }))
  
  self.presentViewController(alert, animated: true, completion: nil)
}

func webViewDidClose(webView: WKWebView) {
  print(__FUNCTION__)
}
}

