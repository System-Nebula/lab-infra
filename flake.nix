{
  description = "NixOS in MicroVMs";

  nixConfig = {
    extra-substituters = [ "https://microvm.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];
  };

  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      microvm,
    }:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} = {
        default = self.packages.${system}.secretcon;
        secretcon = self.nixosConfigurations.secretcon.config.microvm.declaredRunner;
      };

      nixosConfigurations = {
        secretcon = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            ./modules/wazuh.nix
            {
              networking.hostName = "secretcon";
              users.users.root.password = "";
              virtualisation.docker.enable = true;
              virtualisation.oci-containers.backend = "docker";
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              microvm = {
                writableStoreOverlay = "/nix/.rw-store";
                vcpu = 4;
                mem = 8192;
                interfaces = [
                  {
                    type = "user";
                    id = "secretcon";
                    mac = "02:00:00:01:01:01";
                  }
                ];
                volumes = [
                  {
                    mountPoint = "/var";
                    image = "var.img";
                    size = 256;
                  }
                  {
                    image = "nix-store-overlay.img";
                    mountPoint = "/nix/.rw-store";
                    size = 100048;
                  }
                ];
                shares = [
                  {
                    # use proto = "virtiofs" for MicroVMs that are started by systemd
                    proto = "9p";
                    tag = "ro-store";
                    # a host's /nix/store will be picked up so that no
                    # squashfs/erofs will be built for it.
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                  }
                ];

                # "qemu" has 9p built-in!
                hypervisor = "qemu";
                socket = "control.socket";
              };
            }
          ];
        };
      };
    };
}
