import os
import time
import json
import uuid
import threading
from flask import Flask, Response, request, jsonify

app_api = Flask("nemotron-stub-api")
app_metrics = Flask("nemotron-stub-metrics")

requests_waiting_lock = threading.Lock()
requests_waiting = 0

TOKEN_DELAY_SECS = float(os.getenv("TOKEN_DELAY_SECS", "0.05"))
MOCK_RESPONSE_TEXT = os.getenv(
    "MOCK_RESPONSE_TEXT",
    "This is a production-grade mock response from the Nemotron-3 Super 120B "
    "CPU-only stub container running on Google Kubernetes Engine.",
)


@app_api.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    global requests_waiting
    with requests_waiting_lock:
        requests_waiting += 1
    try:
        data = request.get_json() or {}
        stream = data.get("stream", False)
        model = data.get("model", "nemotron-3-super-120b-mock")
        request_id = f"chatcmpl-{uuid.uuid4()}"
        created_time = int(time.time())
        tokens = MOCK_RESPONSE_TEXT.split()

        if stream:
            def generate_stream():
                initial_chunk = {
                    "id": request_id,
                    "object": "chat.completion.chunk",
                    "created": created_time,
                    "model": model,
                    "choices": [
                        {
                            "index": 0,
                            "delta": {"role": "assistant", "content": ""},
                            "finish_reason": None,
                        }
                    ],
                }
                yield f"data: {json.dumps(initial_chunk)}\n\n"
                for i, token in enumerate(tokens):
                    time.sleep(TOKEN_DELAY_SECS)
                    content = f" {token}" if i > 0 else token
                    chunk = {
                        "id": request_id,
                        "object": "chat.completion.chunk",
                        "created": created_time,
                        "model": model,
                        "choices": [
                            {
                                "index": 0,
                                "delta": {"content": content},
                                "finish_reason": None,
                            }
                        ],
                    }
                    yield f"data: {json.dumps(chunk)}\n\n"
                final_chunk = {
                    "id": request_id,
                    "object": "chat.completion.chunk",
                    "created": created_time,
                    "model": model,
                    "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
                }
                yield f"data: {json.dumps(final_chunk)}\n\n"
                yield "data: [DONE]\n\n"

            return Response(generate_stream(), mimetype="text/event-stream")

        time.sleep(len(tokens) * TOKEN_DELAY_SECS)
        return jsonify(
            {
                "id": request_id,
                "object": "chat.completion",
                "created": created_time,
                "model": model,
                "choices": [
                    {
                        "index": 0,
                        "message": {"role": "assistant", "content": MOCK_RESPONSE_TEXT},
                        "finish_reason": "stop",
                    }
                ],
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": len(tokens),
                    "total_tokens": 10 + len(tokens),
                },
            }
        )
    finally:
        with requests_waiting_lock:
            requests_waiting = max(0, requests_waiting - 1)


@app_api.route("/v1/health/ready", methods=["GET"])
def health_ready():
    return jsonify({"status": "ready"}), 200


@app_api.route("/v1/health/live", methods=["GET"])
def health_live():
    return jsonify({"status": "live"}), 200


@app_metrics.route("/metrics", methods=["GET"])
def metrics():
    with requests_waiting_lock:
        current_waiting = requests_waiting
    body = (
        "# HELP vllm:num_requests_waiting Number of requests waiting\n"
        "# TYPE vllm:num_requests_waiting gauge\n"
        f"vllm:num_requests_waiting {current_waiting}\n"
    )
    return Response(body, mimetype="text/plain")


if __name__ == "__main__":
    threading.Thread(
        target=lambda: app_metrics.run(
            host="0.0.0.0", port=9400, debug=False, use_reloader=False
        ),
        daemon=True,
    ).start()
    app_api.run(host="0.0.0.0", port=8000, debug=False, use_reloader=False)
