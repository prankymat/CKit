
//  Copyright (c) 2016, Yuji
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by yuuji on 8/26/16.
//
//

import struct Foundation.Date
import typealias Foundation.TimeInterval

public class User {

    public static var currentUser = User(uid: getuid())
    
    public var pw: passwd = xlibc.passwd()
    
    var bufferptr: UnsafeMutableRawPointer
    
    public var uid: uid_t {
        return pw.pw_uid
    }
    
    public var gid: gid_t {
        return pw.pw_gid
    }

    public var name: String {
        return String(cString: pw.pw_name)
    }

    public var passwd: String {
        return String(cString: pw.pw_passwd)
    }

    public var home: String {
        return String(cString: pw.pw_dir)
    }

    public var shell: String {
        return String(cString: pw.pw_shell)
    }

    #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    public var expiration: Date {
        return Date(timeIntervalSince1970: TimeInterval(pw.pw_expire))
    }

    public var pwdChangeTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(pw.pw_change))
    }

    public var `class`: String {
        return String(cString: pw.pw_class)
    }
    #endif
    
    public init(uid: uid_t) {
        bufferptr = malloc(System.sizes.getpwd_r_bufsize)
        var ptr: UnsafeMutablePointer<passwd>? = nil
        getpwuid_r(uid, &self.pw,
                   bufferptr.assumingMemoryBound(to: Int8.self),
                   System.sizes.getpwd_r_bufsize - 1, &ptr)
    }
    
    public init(name: String) {
        bufferptr = malloc(System.sizes.getpwd_r_bufsize)
        var ptr: UnsafeMutablePointer<passwd>? = nil
        getpwnam_r(name, &self.pw,
                   bufferptr.assumingMemoryBound(to: Int8.self),
                   System.sizes.getpwd_r_bufsize - 1, &ptr)
    }
    
    deinit {
        free(bufferptr)
    }
}

