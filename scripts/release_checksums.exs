[dir] = System.argv()
[_, version] = Regex.run(~r/@version "([^"]+)"/, File.read!("mix.exs"))
targets = ~w(x86_64-linux-gnu aarch64-linux-gnu x86_64-apple-darwin aarch64-apple-darwin)
expected = Enum.map(targets, &"exgboost-nif-2.17-#{&1}-#{version}.tar.gz") |> Enum.sort()
actual = Path.wildcard(Path.join(dir, "*.tar.gz")) |> Enum.map(&Path.basename/1) |> Enum.sort()
if actual != expected do
  raise "Release archives do not match the supported targets. Expected #{inspect(expected)}, got #{inspect(actual)}"
end
checksums = Map.new(expected, fn file ->
  digest = :crypto.hash(:sha256, File.read!(Path.join(dir, file))) |> Base.encode16(case: :lower)
  {file, "sha256:" <> digest}
end)
manifest = "%{\n" <> Enum.map_join(Enum.sort(checksums), "", fn {file, digest} -> "  #{inspect(file)} => #{inspect(digest)},\n" end) <> "}\n"
File.write!("checksum.exs", manifest)
File.write!(Path.join(dir, "SHA256SUMS"), Enum.map_join(Enum.sort(checksums), "", fn {file, "sha256:" <> digest} -> "#{digest}  #{file}\n" end))
IO.puts("Wrote checksums for all #{map_size(checksums)} native packages")
