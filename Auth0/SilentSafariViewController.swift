// SilentSafariViewController.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if os(iOS)
import SafariServices

class SilentSafariViewController: SFSafariViewController, SFSafariViewControllerDelegate {

    private let onResult: (Bool) -> Void

    required init(url URL: URL, callback: @escaping (Bool) -> Void) {
        self.onResult = callback

        if #available(iOS 11.0, *) {
            super.init(url: URL, configuration: SFSafariViewController.Configuration())
        } else {
            super.init(url: URL, entersReaderIfAvailable: false)
        }

        self.delegate = self
        self.view.alpha = 0.05 // Apple does not allow invisible SafariViews, this is the threshold.
        self.modalPresentationStyle = .overCurrentContext
    }

    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        controller.dismiss(animated: false) { self.onResult(didLoadSuccessfully) }
    }

}
#endif
