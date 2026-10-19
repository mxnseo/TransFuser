# TransFuser – mmcv/mmdet-free PyTorch Port & Jetson Remote Inference

[TransFuser (PAMI 2023)](https://arxiv.org/abs/2205.15997) 카메라 + LiDAR 융합 E2E 주행 모델을 **mmcv/mmdet 의존성 없이 순수 PyTorch(torchvision)로 동작**하도록 이식하고,
CARLA 시뮬레이터 PC와 **Jetson AGX Orin을 ZMQ로 연결해 추론을 엣지 디바이스에서 수행**하도록 구성한 저장소

원본: [autonomousvision/transfuser](https://github.com/autonomousvision/transfuser) (2022 branch) · Ubuntu 20.04 · CARLA 0.9.10.1



## 주요 특징

- **mmcv / mmdet 의존성 제거** (`model.py`)
  - Jetson(aarch64)에서는 `mmcv-full`, `mmdet` 빌드가 까다로워, 추론에 필요한 연산만 PyTorch / torchvision / numpy로 재구현
  - 원본 코드는 `model_ori.py`로 보존하여 비교 가능
- **Jetson 원격 추론** (`submission_agent.py`)
  - CARLA 클라이언트(PC)는 센서 입력만 전처리해서 전송, 모델 forward는 Jetson에서 수행
  - ZMQ REQ/REP 소켓 + pickle 직렬화, 송수신 timeout 30s
  - 원본 코드는 `submission_agent_ori.py`로 보존
- **평가 경로 시각화**
  - Town05_long route XML을 route별로 분할하고, `vis_points.py`를 수정해 시작·끝점과 경로 두께를 표시

## 구조

```
[CARLA Server (PC)]
  ↓ RGB 3대 (704×160) + LiDAR BEV (256×256)
[submission_agent.py – 전처리]
  ↓ ZMQ (tcp, pickle)
[Jetson AGX Orin – LidarCenterNet.forward_ego()]
  ↓ pred_wp, bounding_boxes
[submission_agent.py – NMS / PID Controller]
  ↓
[CARLA 차량 제어]
```

## mmcv / mmdet → PyTorch 대체 내역

| 원본 (mmcv / mmdet) | 역할 | 대체 방식 |
| --- | --- | --- |
| `mmcv.cnn.bias_init_with_prob` | bias 초기값 계산 | numpy로 재구현 |
| `mmcv.cnn.normal_init` | 가중치 초기화 | `nn.init.normal_` / `constant_` |
| `mmcv.ops.batched_nms` | 클래스별 NMS | **`torchvision.ops.batched_nms`** |
| `mmcv.runner.force_fp32` | 학습 시 FP32 강제 | 추론 전용이라 no-op decorator |
| `mmdet.core.multi_apply` | 리스트 원소별 함수 적용 | `map` + `zip`으로 재구현 |
| `gaussian_radius`, `gen_gaussian_target` | heatmap target 생성 | numpy / torch로 재구현 |
| `get_local_maximum`, `get_topk_from_heatmap`, `transpose_and_gather_feat` | CenterNet 디코딩 | `F.max_pool2d`, `torch.topk`, `gather`로 재구현 |
| `HEADS.register_module`, `build_loss` | registry / loss 생성 | decorator 제거, 추론 전용으로 loss는 `None` |
| `BaseDenseHead` | head 기반 클래스 | `nn.Module` 상속으로 교체 |
| `BBoxTestMixin` | 테스트 헬퍼 | 호출되지 않아 빈 클래스 |

추가로 `train_cfg.fp16_enabled` 접근을 `getattr(..., False)`로 바꿔 config 누락 시에도 동작하도록 했다.

> 현재 버전은 **추론 전용**이다. loss가 `None`이므로 이 코드로 학습은 불가능하다.

## submission_agent 변경점

| | 원본 | 수정 |
| --- | --- | --- |
| 모델 로드 | 폴더 내 `.pth` 전부 로드 (앙상블) | 로컬 로드 없음, `RemoteInference` 연결 |
| forward | backbone별 분기 후 앙상블 평균 | Jetson에 `forward_ego` 요청, 단일 모델 결과 사용 |
| 종료 | `del self.nets` | ZMQ 소켓 / context 종료 |

## 설치 및 실행

```bash
# 원본 환경
git clone https://github.com/autonomousvision/transfuser.git
cd transfuser && git checkout 2022
./setup_carla.sh
conda env create -f environment.yml && conda activate tfuse

# 이 저장소의 team_code_transfuser/ 로 교체
# (mmcv-full, mmdet, mmsegmentation 설치 불필요)
pip install pyzmq

# Pretrained model
mkdir model_ckpt
wget https://s3.eu-central-1.amazonaws.com/avg-projects/transfuser/models_2022.zip -P model_ckpt
unzip model_ckpt/models_2022.zip -d model_ckpt/
```

```bash
# 1. Jetson: 추론 서버 실행
# 2. PC: CARLA 서버 실행
./carla/CarlaUE4.sh --world-port=2000 -opengl
# 3. PC: 평가 실행
./leaderboard/scripts/local_evaluation.sh <carla_path> <transfuser_path>
```

Jetson 주소는 `submission_agent.py`의 `JETSON_IP`, `JETSON_PORT`에서 설정한다.

## 저장소 구성

```
team_code_transfuser/
├── model.py                 # mmcv/mmdet 제거 버전 (LidarCenterNet, GRU waypoint)
├── model_ori.py             # 원본
├── submission_agent.py      # Jetson 원격 추론 버전
├── submission_agent_ori.py  # 원본
├── transfuser.py            # TransfuserBackbone (Image/LiDAR encoder + Transformer fusion)
├── config.py / data.py / train.py
└── late_fusion.py / geometric_fusion.py / latentTF.py / point_pillar.py
leaderboard/                 # CARLA leaderboard (원본)
```

---

## 공부 기록

- **E2E 주행 기초 논문**
  - NVIDIA DAVE-2 (2016): 단일 카메라 → steering, 좌/우 카메라로 recovery 학습
  - CIL (ICRA 2018): command를 branch 스위치로 사용해 교차로 선택 문제 해결
  - [End to End Learning for Self-Driving Cars & CIL](https://cafe.daum.net/SmartRobot/RoVa/2576)

- **TransFuser 논문 리뷰 및 환경 구축**
  - 입력: 3카메라 stitch 704×160×3 (132° FOV) / LiDAR BEV 256×256×3 (2ch + goal)
  - 4개 해상도에서 Transformer fusion (image 22×5 + LiDAR 8×8 = 174 tokens, velocity embedding)
  - GRU waypoint 예측 (T=4) + Auxiliary tasks (Depth, Semantics, HD Map, BBox)
  - 원본 재현 및 CARLA 주행 영상 저장
  - [TransFuser (PAMI 2023) review & Setup](https://cafe.daum.net/SmartRobot/RoVa/2581)

- **저장소 구조 분석 및 mmcv/mmdet 대체 설계**
  - `transfuser.py`, `model.py`(LidarCenterNet, GRU) 주요 컴포넌트 분석
  - [TransFuser Repository Structure (1)](https://cafe.daum.net/SmartRobot/RoVa/2588)

- **InterFuser / TransFuser / UniAD 평가 환경 비교**
  - Longest6 (36 routes) / 42routes + Town05Long / nuScenes open-loop · Bench2Drive (LB 2.0)
  - 벤치마크 전환 시 필요한 작업 정리 (CARLA 버전, 좌표계, 2Hz → 10Hz, 3 → 6 command)
  - [InterFuser, TransFuser, UniAD 환경 비교](https://cafe.daum.net/SmartRobot/RoVa/2594)

- **CARLA 평가 경로 시각화**
  - `routes_town05_long.xml`을 route별 10개로 분할, `vis_points.py` 수정
  - [CARLA Evaluation Route Visualization](https://cafe.daum.net/SmartRobot/RoVa/2604)

## 관련 프로젝트

- [Capstone_Design – Transfuser-Lite](https://github.com/mxnseo/Capstone_Design): 이 저장소를 기반으로 Transformer 4→2, ResNet-34→18, KD, TensorRT FP16/INT8 경량화 진행
