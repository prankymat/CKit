
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    public let UNIX_PATH_MAX = 104
#elseif os(FreeBSD) || os(Linux)
    public let UNIX_PATH_MAX = 108
#endif

#if os(Linux)
public struct _sockaddr_storage {
    public var ss_family: UInt8 // 1 
    // 127 byte
    public var padding:
    (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)
}
#else
public typealias _sockaddr_storage = xlibc.sockaddr_storage
#endif


public struct SocketAddress {
    #if !os(Linux)
    var storage: _sockaddr_storage
    #else
    var storage: _sockaddr_storage
    #endif
    public init(storage: _sockaddr_storage) {
        self.storage = storage
    }
}

extension SocketAddress : CustomStringConvertible {
    public var description: String {
        let family = "\(self.type)"
        var detail = ""
        switch self.type {
        case .inet, .inet6:
            detail = "\(ip()!):\(port!)"
        default:
            return family
        }
        return family + " " + detail
    }
}

extension sockaddr {
    #if os(Linux)
    public var sa_len: UInt8 {
        return UInt8(MemoryLayout<sockaddr_in6>.size)
    }
    #endif
}

extension _sockaddr_storage {
    #if os(Linux)
    public var ss_len: UInt8 {

        switch self.ss_family {
        case sa_family_t(AF_INET):
            return UInt8(MemoryLayout<sockaddr_in>.size)
            
        case sa_family_t(AF_INET6):
            return UInt8(MemoryLayout<sockaddr_in6>.size)
            
        case sa_family_t(AF_UNIX):
            return UInt8(MemoryLayout<sockaddr_un>.size)
            
        case sa_family_t(AF_LINK):
            return UInt8(MemoryLayout<sockaddr_dl>.size)

        default:
            return UInt8(MemoryLayout<sockaddr>.size)
        }
        
    }
    #endif
}

extension sockaddr_in {
    init(port: in_port_t, addr: in_addr = in_addr(s_addr: 0)) {
        #if os(Linux)
            self = sockaddr_in(sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr: 0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #else
            self = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr:0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #endif
    }
    
    #if os(Linux)
    public var sin_len: UInt8 {
        return UInt8(MemoryLayout<sockaddr_in>.size)
    }
    #endif
}

extension sockaddr_in6 {
    init(port: in_port_t, addr: in6_addr = in6addr_any) {
        #if os(Linux)
            self = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #else
            self = sockaddr_in6(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #endif
    }
    
    #if os(Linux)
    public var sin6_len: UInt8 {
        return UInt8(MemoryLayout<sockaddr_in6>.size)
    }
    #endif
}

extension SocketAddress {
    public init(addr: UnsafePointer<sockaddr>) {
        self.storage = _sockaddr_storage()
        #if !os(Linux)
        memcpy(mutablePointer(of: &self.storage).mutableRawPointer, addr.rawPointer, Int(addr.pointee.sa_len))
        #else
            var len = MemoryLayout<sockaddr>.size
            
            switch SocketDomains(rawValue: addr.pointee.sa_family)! {
            case .inet:
                len = MemoryLayout<sockaddr_in>.size
                
            case .inet6:
                len = MemoryLayout<sockaddr_in6>.size
                
            case .unix:
                len = MemoryLayout<sockaddr_un>.size
            
            case .link:
                len = MemoryLayout<sockaddr_dl>.size
                
//            case .x25:
//                len = MemoryLayout<sockaddr_x25>.size
//                
//            case .ipx:
//                len = MemoryLayout<sockaddr_ipx>.size
//                
//            case .ax25:
//                len = MemoryLayout<sockaddr_ax25>.size
//                
                
            default:
                break
            }
            
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer, addr.rawPointer, len)
        #endif
    }
    
    public init?(domain: SocketDomains, port: in_port_t) {
        switch domain {
        case .inet:
            self.storage = _sockaddr_storage()
            var addr = sockaddr_in(port: port)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   MemoryLayout<sockaddr_in>.size)
            
        case .inet6:
            self.storage = _sockaddr_storage()
            var addr = sockaddr_in6(port: port)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   MemoryLayout<sockaddr_in>.size)
        default:
            return nil
        }
    }
    
    public init?(ip: String, domain: SocketDomains, port: in_port_t = 0) {
        switch domain {
        case .inet:
            self.storage = _sockaddr_storage()
            var addr = sockaddr_in(port: port)
            inet_pton(AF_INET, ip.cString(using: .ascii),
                      mutablePointer(of: &(addr.sin_addr)).mutableRawPointer)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   Int(addr.sin_len))
            
        case .inet6:
            self.storage = _sockaddr_storage()
            var addr = sockaddr_in6(port: port)
            inet_pton(AF_INET6, ip.cString(using: .ascii),
                      mutablePointer(of: &(addr.sin6_addr)).mutableRawPointer)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   Int(addr.sin6_len))
            
        default:
            return nil
        }
    }
    
    public init?(unixPath: String) {
        self.storage = _sockaddr_storage()
        self.storage.ss_family = sa_family_t(AF_UNIX)
        #if !os(Linux)
        self.storage.ss_len = UInt8(MemoryLayout<sockaddr_un>.size)
        strncpy(mutablePointer(of: &(self.storage.__ss_pad1)).cast(to: Int8.self),
                unixPath.cString(using: .utf8)!,
                UNIX_PATH_MAX)
        #else
        var addr = sockaddr_un()
        strncpy(mutablePointer(of: &(addr.sun_path)).cast(to: Int8.self),
                unixPath.cString(using: .utf8)!,
                UNIX_PATH_MAX)
        memcpy(mutablePointer(of: &self.storage).mutableRawPointer, pointer(of: &addr).rawPointer, MemoryLayout<sockaddr_un>.size)
        #endif
    }
    
    #if !os(Linux)
    public init?(linkAddress: String) {
        self.storage = _sockaddr_storage()
        self.storage.ss_family = sa_family_t(AF_LINK)
        self.storage.ss_len = UInt8(MemoryLayout<sockaddr_un>.size)
        link_addr(linkAddress.cString(using: .ascii), mutablePointer(of: &self.storage).cast(to: sockaddr_dl.self))
    }
    #endif
}

extension SocketAddress {
    public var len: socklen_t {
        return socklen_t(storage.ss_len)
    }
    
    public var type: SocketDomains {
        return SocketDomains(rawValue: storage.ss_family)!
    }
    
    public func addr() -> sockaddr {
        return unsafeBitCast(storage, to: sockaddr.self)
    }
    
    public var socklen: socklen_t {
        #if !os(Linux)
        return socklen_t(self.storage.ss_len)
        #else
            switch self.type {
            case .inet:
                return socklen_t(MemoryLayout<sockaddr_in>.size)
                
            case .inet6:
                return socklen_t(MemoryLayout<sockaddr_in6>.size)
                
            case .unix:
                return socklen_t(MemoryLayout<sockaddr_un>.size)
                
            case .link:
                return socklen_t(MemoryLayout<sockaddr_dl>.size)
                
//            case .x25:
//                return socklen_t(MemoryLayout<sockaddr_x25>.size)
//                
//            case .ipx:
//                return socklen_t(MemoryLayout<sockaddr_ipx>.size)
//                
//            case .ax25:
//                return socklen_t(MemoryLayout<sockaddr_ax25>.size)

            default:
                return socklen_t(MemoryLayout<sockaddr>.size)
            }
        #endif
    }
    
    public mutating func addrptr() -> UnsafePointer<sockaddr> {
        return pointer(of: &storage).cast(to: sockaddr.self)
    }
    
    public var port: in_port_t? {
        switch self.type {
        case .inet:
            return unsafeBitCast(storage, to: sockaddr_in.self).sin_port.byteSwapped
        case .inet6:
            return unsafeBitCast(storage, to: sockaddr_in6.self).sin6_port.byteSwapped
        default:
            return nil
        }
    }
    
    public func ip() -> String? {
        var buffer = [Int8](repeating: 0, count: System.maximum.pathname)
        var addr = self.storage
        
        switch self.type {
        case .inet:
            inet_ntop(AF_INET, pointer(of: &addr).rawPointer, &buffer, self.len)
        case .inet6:
            inet_ntop(AF_INET6, pointer(of: &addr).rawPointer, &buffer, self.len)
        default:
            return nil
        }
        return String(cString: buffer)
    }
    
    public func path() -> String? {
        if self.type != .unix {
            return nil
        }
        var stor = storage
        var buffer = [Int8](repeating: 0, count: System.maximum.pathname + 1)
        var addr = sockaddr_un()
        memcpy(mutablePointer(of: &addr).mutableRawPointer,
               pointer(of: &stor).rawPointer, MemoryLayout<sockaddr_un>.size)
        strncpy(&buffer, pointer(of: &addr.sun_path).cast(to: Int8.self), Int(System.maximum.pathname))
        return String(cString: buffer)
    }
}
