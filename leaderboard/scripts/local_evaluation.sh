# export CARLA_ROOT=${1:-/home/kchitta/Documents/CARLA_0.9.10.1}
# export WORK_DIR=${2:-/home/kchitta/Documents/transfuser}

# export CARLA_SERVER=${CARLA_ROOT}/CarlaUE4.sh
# export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI
# export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI/carla
# export PYTHONPATH=$PYTHONPATH:$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.10-py3.7-linux-x86_64.egg
# export SCENARIO_RUNNER_ROOT=${WORK_DIR}/scenario_runner
# export LEADERBOARD_ROOT=${WORK_DIR}/leaderboard
# export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/":"${SCENARIO_RUNNER_ROOT}":"${LEADERBOARD_ROOT}":${PYTHONPATH}

# export SCENARIOS=${WORK_DIR}/leaderboard/data/longest6/eval_scenarios.json
# export ROUTES=${WORK_DIR}/leaderboard/data/longest6/longest6.xml
# export REPETITIONS=1
# export CHALLENGE_TRACK_CODENAME=SENSORS
# export CHECKPOINT_ENDPOINT=${WORK_DIR}/results/transfuser_longest6.json
# export TEAM_AGENT=${WORK_DIR}/team_code_transfuser/submission_agent.py
# export TEAM_CONFIG=${WORK_DIR}/model_ckpt/transfuser
# export DEBUG_CHALLENGE=0
# export RESUME=1
# export DATAGEN=0

# python3 ${LEADERBOARD_ROOT}/leaderboard/leaderboard_evaluator_local.py \
# --scenarios=${SCENARIOS}  \
# --routes=${ROUTES} \
# --repetitions=${REPETITIONS} \
# --track=${CHALLENGE_TRACK_CODENAME} \
# --checkpoint=${CHECKPOINT_ENDPOINT} \
# --agent=${TEAM_AGENT} \
# --agent-config=${TEAM_CONFIG} \
# --debug=${DEBUG_CHALLENGE} \
# --resume=${RESUME}


export CARLA_ROOT=${1:-/home/airlab/transfuser/carla}
export WORK_DIR=${2:-/home/airlab/transfuser}

export CARLA_SERVER=${CARLA_ROOT}/CarlaUE4.sh
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI/carla
export PYTHONPATH=$PYTHONPATH:$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.10-py3.7-linux-x86_64.egg
export SCENARIO_RUNNER_ROOT=${WORK_DIR}/scenario_runner
export LEADERBOARD_ROOT=${WORK_DIR}/leaderboard
export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/":"${SCENARIO_RUNNER_ROOT}":"${LEADERBOARD_ROOT}":${PYTHONPATH}

export SCENARIOS=${WORK_DIR}/leaderboard/data/longest6/eval_scenarios.json # 어떤 시나리오 쓸지 (난이도)
# 옵션:
# leaderboard/data/longest6/eval_scenarios.json  → longest6 공식 시나리오
# leaderboard/data/scenarios/no_scenarios.json   → 시나리오 없음 (쉬움)
# leaderboard/data/Town10HD_Scenario10.json      

export ROUTES=${WORK_DIR}/leaderboard/data/longest6/longest6.xml # 루트 어디 돌지 (경로)
# 옵션:
# leaderboard/data/longest6/longest6.xml         → 논문 기준 6개 맵 36루트
# leaderboard/data/routes_town10.xml             → Town10만 24루트
# leaderboard/data/routes_debug.xml              → 1~2루트 (빠른 테스트)

export REPETITIONS=1 # 반복 횟수
export CHALLENGE_TRACK_CODENAME=SENSORS
export CHECKPOINT_ENDPOINT=${WORK_DIR}/results/transfuser_longest6.json
export TEAM_AGENT=${WORK_DIR}/team_code_transfuser/submission_agent.py
export TEAM_CONFIG=${WORK_DIR}/model_ckpt/models_2022/transfuser # 모델 찾는 경로
export DEBUG_CHALLENGE=0 # 디버그 모드 수정, 0(비활성화), 1(활성화)
export RESUME=1 # 이어서 할 건지 (1), 새로 할 건지 (0)
export DATAGEN=0 # 데이터 수집 모드, 0(비활성화), 1(활성화)

python3 ${LEADERBOARD_ROOT}/leaderboard/leaderboard_evaluator_local.py \
--scenarios=${SCENARIOS}  \
--routes=${ROUTES} \
--repetitions=${REPETITIONS} \
--track=${CHALLENGE_TRACK_CODENAME} \
--checkpoint=${CHECKPOINT_ENDPOINT} \
--agent=${TEAM_AGENT} \
--agent-config=${TEAM_CONFIG} \
--debug=${DEBUG_CHALLENGE} \
--resume=${RESUME}

