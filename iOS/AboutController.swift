/*
 * Copyright (c) 2016 - 2021 Jonathan Schleifer <js@nil.im>
 *
 * https://fossil.nil.im/cryptopassphrase
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

class AboutController: UIViewController, UIWebViewDelegate {
    @IBOutlet var webView: UIWebView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        webView?.loadHTMLString(
            "<html>" +
            "<head>" +
            "<style type='text/css'>" +
            "body {" +
            "    font-family: sans-serif;" +
            "}" +
            "" +
            "#title {" +
            "    font-size: 2.1em;" +
            "    font-weight: bold;" +
            "    text-align: center;" +
            "}" +
            "" +
            "#copyright {" +
            "    font-size: 0.9em;" +
            "    font-weight: bold;" +
            "    text-align: center;" +
            "}" +
            "</style>" +
            "</head>" +
            "<body>" +
            "<div id='title'>" +
            "  CryptoPassphrase \(version ?? "")" +
            "</div>" +
            "<div id='copyright'>" +
            "  Copyright © 2016 - 2021 Jonathan Schleifer" +
            "</div>" +
            "<p name='free_software'>" +
            "  CryptoPassphrase is free software and the source code is" +
            "  available at" +
            "  <a href='https://fossil.nil.im/cryptopassphrase'>here</a>." +
            "</p>" +
            "<p name='objfw'>" +
            "  It makes use of the" +
            "  <a href='https://objfw.nil.im/'>ObjFW</a> framework and also" +
            "  uses its scrypt implementation." +
            "</p>" +
            "</body>" +
            "</html>", baseURL: nil)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest,
                 navigationType: UIWebView.NavigationType) -> Bool {
        if #available(iOS 10.0, *),
           navigationType == UIWebView.NavigationType.linkClicked,
           let url = request.url {
            UIApplication.shared.open(url)
            return false
        }

        return true
    }
}
