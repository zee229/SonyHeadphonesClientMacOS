import Foundation

extension MDRHeadphones {

    /// Port of RequestSyncV2 from HeadphonesV2.cpp.
    /// Queries battery status and safe listening sound pressure.
    public func requestSyncV2() {
        setTaskRunning(true)

        // Single Battery
        if support.contains(.BATTERY_LEVEL_INDICATOR) {
            queueCommand(PowerGetStatus(type: .BATTERY))
        } else if support.contains(.BATTERY_LEVEL_WITH_THRESHOLD) {
            queueCommand(PowerGetStatus(type: .BATTERY_WITH_THRESHOLD))
        }

        // L + R Battery
        if support.contains(.LEFT_RIGHT_BATTERY_LEVEL_INDICATOR) {
            queueCommand(PowerGetStatus(type: .LEFT_RIGHT_BATTERY))
        } else if support.contains(.LR_BATTERY_LEVEL_WITH_THRESHOLD) {
            queueCommand(PowerGetStatus(type: .LR_BATTERY_WITH_THRESHOLD))
        }

        // Case Battery
        if support.contains(.CRADLE_BATTERY_LEVEL_INDICATOR) {
            queueCommand(PowerGetStatus(type: .CRADLE_BATTERY))
        } else if support.contains(.CRADLE_BATTERY_LEVEL_WITH_THRESHOLD) {
            queueCommand(PowerGetStatus(type: .CRADLE_BATTERY_WITH_THRESHOLD))
        }

        // Sound Pressure
        if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1) {
            queueCommand(SafeListeningGetExtendedParam(type: .SAFE_LISTENING_HBS_1), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_2) {
            queueCommand(SafeListeningGetExtendedParam(type: .SAFE_LISTENING_HBS_2), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_TWS_1) {
            queueCommand(SafeListeningGetExtendedParam(type: .SAFE_LISTENING_TWS_1), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_TWS_2) {
            queueCommand(SafeListeningGetExtendedParam(type: .SAFE_LISTENING_TWS_2), type: .dataMdrNo2)
        }

        setQueueDrainCallback { [self] in
            setTaskResult(MDREvent.taskSyncOK.rawValue)
        }
    }
}
