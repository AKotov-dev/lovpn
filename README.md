# lovpn
`Lovpn` - is a simple loader of free password-free OpenVPN configurations (*.ovpn) from open sources. Don't forget to open the `iptables` ports.

**Dependencies:** curl gtk2

![](https://github.com/AKotov-dev/lovpn/blob/main/ScreenShot1.png)

Specify the download directory and click the `Start` button. Since the configurations are free, there will be non-working ones among them, but most of them work. In total, about `300` configurations are loaded. To connect, it is convenient to use [Luntik](https://github.com/AKotov-dev/luntik) or [OpenVPN-GUI](https://github.com/AKotov-dev/OpenVPN-GUI). RPM and DEB packages are presented.  
  
**Life hack:** Since `Lovpn` downloads free configurations, the connection to which is not very fast, you can use [Juggler](https://github.com/AKotov-dev/juggler) to connect through them to high-speed VPN providers blocked in your countries.
