fn main() {
    println!("cargo:rustc-link-lib=dylib=synthesizer-hs");
    println!(
        "cargo:rustc-link-search=native=../synthesizer-hs/dist-newstyle/build/x86_64-linux/ghc-9.6.7/synthesizer-hs-0.1.0.0/f/synthesizer-hs/build/synthesizer-hs"
    );
    println!(
        "cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/../../../synthesizer-hs/dist-newstyle/build/x86_64-linux/ghc-9.6.7/synthesizer-hs-0.1.0.0/f/synthesizer-hs/build/synthesizer-hs"
    );
    println!(
        "cargo:rustc-link-arg-examples=-Wl,-rpath,$ORIGIN/../../../../synthesizer-hs/dist-newstyle/build/x86_64-linux/ghc-9.6.7/synthesizer-hs-0.1.0.0/f/synthesizer-hs/build/synthesizer-hs"
    );
}
