/system script set [find name="Canh_Bao_Dang_Nhap"] source={
:global lastLogId
:global lastVpnNotifTime
:local homNay [:pick [/system clock get date] 0 6]
:local allLogs [/log find topics~"account|l2tp|ipsec"]

:if ([:len $allLogs] > 0) do={
    :if ([:typeof $lastLogId] = "nothing") do={
        :set lastLogId ($allLogs->([:len $allLogs] - 1))
    } else={
        :local failedLogs ""
        :local failCount 0
        :local vpnLog ""
        :local foundOld false
        :foreach i in=$allLogs do={
            :if ($i = $lastLogId) do={
                :set foundOld true
            } else={
                :local msg [/log get $i message]
                :local t [/log get $i time]
                :if ([:find $t $homNay] != nil || [:len $t] = 8) do={
                    :if (([:find $msg "login failure"] != nil) || ([:find $msg "authentication failed"] != nil)) do={
                        :if ($foundOld = true || [:len $t] = 8) do={
                            :set failedLogs ($failedLogs . "- [" . $t . "] " . $msg . "\r\n")
                            :set failCount ($failCount + 1)
                        }
                    }
                    :if (([:find $msg "logged in from"] != nil) && (([:find $msg "via l2tp"] != nil) || ([:find $msg "via ipsec"] != nil))) do={
                        :if ($foundOld = true || [:len $t] = 8) do={
                            :set vpnLog ("- [" . $t . "] " . $msg)
                        }
                    }
                }
            }
        }
        :set lastLogId ($allLogs->([:len $allLogs] - 1))
        :if ($failCount > 0) do={
            /tool e-mail send to="nguyenvanphuoc1981@gmail.com" subject=("[LTV-MikroTik] CANH BAO DO MAT KHAU (" . $failCount . " lan)") body=("Phat hien thu dang nhap sai mat khau Winbox/VPN:\r\n\r\n" . $failedLogs)
        }
        :if ($vpnLog != "") do={
            :local curUp [/system resource get uptime]
            :if ([:typeof $lastVpnNotifTime] = "nothing" || ($curUp - $lastVpnNotifTime) >= 4h) do={
                /tool e-mail send to="nguyenvanphuoc1981@gmail.com" subject="[LTV-MikroTik] Ket noi VPN quan tri tu xa" body=("Phat hien ket noi VPN thanh cong vao Router:\r\n\r\n" . $vpnLog)
                :set lastVpnNotifTime $curUp
            }
        }
    }
}
}
/system scheduler enable [find on-event~"Canh_Bao_Dang_Nhap"]
