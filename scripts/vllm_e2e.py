# SPDX-License-Identifier: Apache-2.0
"""Exercise two vLLM requests with a shared prefix through LMCache InProcess."""

# Standard
import importlib
import os

# Third Party
from vllm import LLM, SamplingParams
from vllm.config import KVTransferConfig


def main() -> None:
    """Run two requests whose second prompt must reuse the first prompt's KV."""
    connector_module_path = "lmcache.inprocess.integration.vllm.lmcache_connector_v1"
    connector_module = importlib.import_module(connector_module_path)
    connector_file = connector_module.__file__
    assert connector_file is not None
    assert connector_file.endswith("/lmcache_connector_v1.py")
    print(f"LMCACHE_INPROCESS_CONNECTOR_MODULE={connector_module_path}")
    print(f"LMCACHE_INPROCESS_CONNECTOR_FILE={connector_file}")

    model = os.environ.get("LMCACHE_E2E_MODEL", "Qwen/Qwen3-0.6B")
    shared_prefix = (
        "LMCache stores reusable key value tensors for language model inference. "
        "This sentence intentionally repeats to create a cacheable shared prefix. "
    ) * 40

    llm = LLM(
        model=model,
        kv_transfer_config=KVTransferConfig(
            kv_connector="LMCacheConnectorV1Dynamic",
            kv_connector_module_path=connector_module_path,
            kv_role="kv_both",
        ),
        max_model_len=2048,
        gpu_memory_utilization=0.5,
        enforce_eager=True,
    )
    sampling = SamplingParams(temperature=0, max_tokens=1)

    first = llm.generate([shared_prefix + " First request."], sampling)
    second = llm.generate([shared_prefix + " Second request."], sampling)

    assert first[0].outputs
    assert second[0].outputs
    print("LMCACHE_INPROCESS_E2E_REQUESTS_COMPLETED=2")


if __name__ == "__main__":
    main()
