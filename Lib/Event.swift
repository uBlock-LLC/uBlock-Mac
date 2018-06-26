/*******************************************************************************
 
 µBlock - the most powerful, FREE ad blocker.
 Copyright (C) 2018 The µBlock authors
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see {http://www.gnu.org/licenses/}.
 
 Home: https://github.com/uBlock-LLC/uBlock-Mac
 */

//  see: http://blog.scottlogic.com/2015/02/05/swift-events.html

/// An object that has some tear-down logic
public protocol Disposable {
    func dispose()
}


/// An event provides a mechanism for raising notifications, together with some
/// associated data. Multiple function handlers can be added, with each being invoked,
/// with the event data, when the event is raised.
public class Event<T> {
    
    public typealias EventHandler = (T) -> Void
    
    fileprivate var eventHandlers = [Invocable]()
    
    public init() {
    }
    
    /// Raises the event, invoking all handlers
    public func raise(data: T) {
        for handler in self.eventHandlers {
            handler.invoke(data: data)
        }
    }
    
    /// Adds the given handler
    public func addHandler<U: AnyObject>(target: U, handler: @escaping (U) -> EventHandler) -> Disposable {
        let wrapper = EventHandlerWrapper(target: target, handler: handler, event: self)
        eventHandlers.append(wrapper)
        return wrapper
    }
}

// MARK:- Private

// A protocol for a type that can be invoked
private protocol Invocable: class {
    func invoke(data: Any)
}

// takes a reference to a handler, as a class method, allowing
// a weak reference to the owning type.
// see: http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/
private class EventHandlerWrapper<T: AnyObject, U> : Invocable, Disposable {
    weak var target: T?
    let handler: (T) -> (U) -> Void
    let event: Event<U>
    
    init(target: T?, handler: @escaping (T) -> (U) -> Void, event: Event<U>){
        self.target = target
        self.handler = handler
        self.event = event;
    }
    
    func invoke(data: Any) {
        if let t = target {
            handler(t)(data as! U)
        }
    }
    
    func dispose() {
        event.eventHandlers = event.eventHandlers.filter { $0 !== self }
    }
}
