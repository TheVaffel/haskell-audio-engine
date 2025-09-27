fn main() {
    println!("cargo:rustc-link-lib=dylib=audio-engine");
    println!(
        "cargo:rustc-link-search=native=../audio-engine/dist-newstyle/build/x86_64-linux/ghc-9.6.7/audio-engine-0.1.0.0/f/audio-engine/build/audio-engine"
    );
    println!(
        "cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/../../../audio-engine/dist-newstyle/build/x86_64-linux/ghc-9.6.7/audio-engine-0.1.0.0/f/audio-engine/build/audio-engine"
    );
}
