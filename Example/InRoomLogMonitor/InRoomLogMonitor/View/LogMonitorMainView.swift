//
//  ContentView.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/10/26.
//

import SwiftUI
import InRoomLogger

struct LogMonitorMainView: View {
    @EnvironmentObject var monitor: InRoomLogMonitor
    @State var logHistory: [LogInformationIdentified] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(self.logHistory) { log in
                    Text(generateMessage(with: log))
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .padding(20)
            .onChange(of: monitor.logHistory) { logHistory in
                self.logHistory = logHistory
            }
            .onAppear {
                self.logHistory = monitor.logHistory
            }
        }
    }
    
    // stringが空でなければstringの前にspacerを追加する
    func addSeparater(_ string: String, prefix: String = " ") -> String {
        guard !string.isEmpty else { return "" }

        return "\(prefix)\(string)"
    }

    // swiftlint:disable switch_case_on_newline
    func prefix(with info: LogInformation) -> String {
        if let prefix = info.prefix {
            return prefix
        }

        switch info.level {
            case .log: return ""
            case .debug: return "#DEBG"
            case .info: return "#INFO"
            case .warning: return "#WARN"
            case .error: return "#🔥"
            case .fault: return "#🔥🔥"
        }
    }

    func generateMessage(with info: LogInformation) -> String {
        let prefix = prefix(with: info)
        return info.level == .info ?
            "\(prefix)\(addSeparater(info.message)) [\(info.objectName)]" :
            "\(prefix) [\(info.timestamp())]\(addSeparater(info.message)) [\(info.threadName)] [\(info.objectName)] \(info.fileName): \(info.line))"
    }
}

struct LogMonitorMainView_Previews: PreviewProvider {
    static var previews: some View {
        LogMonitorMainView()
    }
}
