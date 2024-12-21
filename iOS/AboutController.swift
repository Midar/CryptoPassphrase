/*
 * Copyright (c) 2016 - 2024 Jonathan Schleifer <js@nil.im>
 *
 * https://fl.nil.im/cryptopassphrase
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
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
