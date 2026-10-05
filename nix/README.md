# NixOS on the Framework Laptop 13 Pro

This configuration prepares a Hyprland workstation for the Intel Framework Laptop 13 Pro and a separate VM for testing it before delivery. The expected CPU is the Core Ultra X9 388H with integrated Arc B390 graphics. The laptop has 64 GB RAM and a 2 TB SSD.

The VM and laptop share `workstation.nix` and the per-tool Home Manager modules. The VM has its own UEFI bootloader and disk image. Its software-rendered desktop cannot establish laptop GPU compatibility or performance.

## Run the rehearsal on Windows

From the repository root in PowerShell:

```powershell
.\nix\setup-builder.ps1
.\nix\rehearse.ps1 check
.\nix\rehearse.ps1 verify
.\nix\rehearse.ps1 web
```

The setup script creates a separate WSL distribution named `NixOS-Rehearsal` at `E:\VMs\NixOS-Rehearsal`. It verifies the pinned NixOS-WSL archive's SHA-256 before importing it. Existing WSL distributions and the default distribution stay as they are. Pass `-Name` and `-Directory` to change the builder location, then pass the same `-Builder` to `rehearse.ps1`.

The first build downloads the desktop and development packages. `build` builds without starting a window. `verify` boots the VM in the background, checks UEFI boot, Home Manager, the Hyprland session, tmux, Neovim and development-tool execution, saves a screenshot and shuts it down.

`web` starts the VM with a [local browser console](http://localhost:6080/vnc.html?autoconnect=1&resize=scale). Keep the launching PowerShell window open, then open that link. The console's left toolbar has full-screen and extra-key controls. Both the browser console and its VNC connection bind only to loopback. This mode works independently of WSLg; the native `run` mode failed with `gtk initialization failed` on this PC. `run` remains available for systems with a working WSLg display service.

The VM uses four virtual CPUs, 8 GB RAM and a sparse disk with a 48 GB virtual capacity. Shut down from a guest terminal with `sudo poweroff`; the browser-console process stops when the VM exits. Closing the browser tab alone leaves the VM running.

The disposable guest logs into Hyprland automatically. Its username is `stephanvs` and its test password is `rehearsal`. SSH is forwarded only to the builder's loopback address at port 2222. These settings belong only to the VM profile.

The builder copies the configuration inputs into a separate source directory before evaluating them, so new files need not be staged in Git. Packages are pinned in the root `flake.lock`. VM state lives under `/root/nixos-rehearsal/runs` inside the builder. A changed VM build gets a fresh disk; restarting the same build retains its disk. Each run keeps a Nix garbage-collection root for its backing image. This prevents an old installed VM from hiding configuration changes or losing its backing image during garbage collection. Keeping several builds also uses more disk space.

The desktop preserves the existing no-animation preference, keyboard navigation, wallpaper, Berkeley Mono font, terminal colors and Starship settings. Super+Return opens Ghostty, Super+Shift+Return opens Firefox, Super+Space opens the launcher, and Super+Escape locks the session.

The package set includes .NET 10, Node.js 24, Rust, Neovim, Git, lazygit, Firefox and 1Password. Your tmux preferences, PowerKit theme, custom usage plugins and session/popup bindings are shared with the existing configuration. The Nix profile supplies tmux plugins, sesh, gum, yazi, OpenCode, Claude Code, Gemini CLI and Codex.

Neovim uses the existing NvChad configuration with Nix-supplied plugins, parsers, language servers, Stylua and the Supermaven agent. Lazy and Mason do not download packages in this profile. Custom plugin revisions are locked in `flake.lock`; packaged plugins follow the locked nixpkgs revision. Other operating systems retain the existing Lazy/TPM setup. The current Tree-sitter configuration uses nixpkgs' legacy package, which must be migrated before upgrading to NixOS 26.11.

Sign into 1Password and enable its SSH agent inside the guest when testing that workflow. GitHub HTTPS authentication uses `gh auth login`. AI assistants and usage widgets also need their own authentication. Credentials are not copied from Windows.

## Verified on 5 October 2026

The VM was built and booted with KVM inside the separate WSL builder on the existing Windows PC. Automated checks passed for UEFI boot, the ext4 root filesystem, Home Manager activation, Hyprland configuration and an active display, Waybar, hyprpaper, hypridle, Mako notification delivery, Ghostty configuration and window creation, tmux shell execution and pane creation, sesh session discovery, and execution of small JavaScript, Rust and .NET console programs. The graphical session and SSH sessions share the Home Manager environment, including the tmux socket location.

The Neovim check runs in a terminal pane. It opens a TypeScript project and waits for the language server to report a deliberate type error, parses Lua, TypeScript, Rust and C# source, and formats a Lua buffer with Stylua. These checks passed in the VM. Fresh and repeated editor launches also passed in an isolated builder home directory. A screenshot confirmed that the wallpaper, status bar, PowerKit theme and terminal panes rendered. Fontconfig selected the repository's Berkeley Mono font.

Flake evaluation, Nix formatting, ShellCheck and PowerShell syntax checks passed. The Framework module evaluates with kernel 7.2.9 and libvirt enabled. These checks establish the desktop and core development rehearsal; they do not establish complete application parity or physical laptop compatibility.

`verify` saves `verification.log`, `boot.log` and `desktop.png` in the current run directory, then shuts the VM down. A failed guest check also saves the user-session journal as `desktop.log`. To find that directory inside the builder, run:

```bash
printf '/root/nixos-rehearsal/runs/%s\n' "$(basename "$(readlink -f /root/nixos-rehearsal/result)")"
```

## Migration still to finish

The rest of the Brew/Scoop inventory, the custom lazygit AI-commit command, additional shell integrations and project-specific SDK versions still need a migration pass. The current selection covers the desktop, terminal and core development tools. Hyprland uses its supported legacy configuration format to carry over the current preferences; a Lua migration can be done separately.

Before relying on this as the daily workstation, verify the representative .NET, Rust and JavaScript projects, browser screen sharing, 1Password SSH authentication, lock/unlock and clipboard behavior in the VM. Hardware acceptance also needs Wi-Fi, Bluetooth, suspend/resume, audio, camera, brightness, touchpad and external-display checks on the laptop.

## Laptop installation

`nixosModules.framework` exports the shared configuration with the upstream `framework-intel-core-ultra-series3` hardware module, a current kernel and libvirt. It is not yet an installable laptop target: the hardware-generated filesystem configuration and final disk layout are deliberately absent.

After the laptop arrives, generate `hardware-configuration.nix` from the actual mounted filesystems and compose it with `self.nixosModules.framework` in a `nixosConfigurations.framework` target. Set the real user's password during installation. The target is NixOS as the sole host OS. Decide encryption and swap/hibernation before partitioning the SSD.

[Framework's NixOS guide](https://guides.frame.work/Guide/NixOS+on+the+Framework+Laptop+13+Pro/780) links to the [exact hardware module instructions](https://github.com/FrameworkComputer/linux-docs/blob/main/framework13/FW-13-Pro-NixOS-all-Intel-Core-Ultra-Series-3.md). Its automatic partitioning example erases a whole disk; confirm the selected disk and final layout on the actual machine before installing.

## Prepar3D and Windows

Prepar3D must run on the laptop without an external GPU. The target is a GPU-accelerated Windows VM under NixOS, with no dual-boot requirement. The existing PC remains the work machine until the laptop passes the actual simulator workload. Dual boot is a contingency to reconsider only if the hardware cannot support the target; there is no delivery deadline that requires accepting a reduced setup. A temporary native-Windows comparison can help distinguish Intel driver or application problems from virtualization problems.

Intel lists Panther Lake as supporting SR-IOV graphics sharing between a Linux host and Windows/Linux guests. Its [SR-IOV toolkit](https://github.com/intel/GFX-SRIOV-Toolkit) lists Panther Lake with kernel 6.18 and validates Ubuntu 24.04.4 hosts and Windows 11 Enterprise 24H2 guests. This is promising platform evidence, not a verified NixOS/Framework/Prepar3D combination. [Intel's platform support table](https://www.intel.com/content/www/us/en/support/articles/000093216/graphics/processor-graphics.html) and [Windows guest instructions](https://github.com/intel/kvm-multios/blob/main/documentation/windows_vm.md) describe the required driver stack.

Sharing the integrated GPU through SR-IOV is the candidate to test. Assigning the entire GPU to Windows would also take it away from the Linux desktop. A generic emulated graphics adapter does not establish [Prepar3D v5's DirectX 12 and feature-level 12_0 requirements](https://www.prepar3d.com/product-overview/system-requirements/).

There is also [first-hand Framework 13 Pro evidence](https://community.frame.work/t/is-intel-gpu-sr-iov-gpu-passthrough-with-kvm-qemu-for-windows-11vm-possible/84345): an X7 358H owner reported Windows 11 and Looking Glass working with the Arc B390 on Gentoo and kernel 7.2.6. They still wanted to improve video performance. Another owner reported success on CachyOS. These reports support investigating this route, but neither establishes Prepar3D performance on the X9 configuration.

On the physical Framework, collect a read-only report:

```bash
bash nix/probe-framework.sh
```

Then verify firmware/IOMMU support, exposed GPU virtual functions, compatible Windows graphics and display drivers, the internal-screen presentation path, simulator startup and the actual work scenario. Check frame rate, latency, graphics correctness, restart and suspend/resume. No passthrough settings are enabled automatically by this configuration.
